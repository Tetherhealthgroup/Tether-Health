"""The `.sql` migrations and `thsync.schema` must describe the same tables.

The migrations are what production runs; the `MetaData` is what the tests run
against and what every query is built from. Nothing enforces that they agree,
and the failure mode if they do not is the worst kind: a green test suite and a
column that does not exist on the server.

**How types are compared without a Postgres server.** There is no PostgreSQL in
the environment this was written in — the sandbox denies `shmget`, so even
`initdb` cannot bootstrap a cluster. But comparing types does not need a
server, only PostgreSQL's parser, and that is available as a library:
`pglast` wraps `libpg_query`, which is the real `gram.y` lifted out of the
server source.

So both sides are put through it. The migration's `timestamptz` and
SQLAlchemy's `TIMESTAMP WITH TIME ZONE` are different spellings that the
parser canonicalises to the same internal name, as are `boolean`/`bool` and
`bigint`/`int8`. Comparing the parsed forms therefore compares meaning rather
than text, and it does it with the same code the server would use.

What this still cannot prove is runtime behaviour — that a `timestamptz`
round-trips the offset the client sent, or that `jsonb` accepts every document
the app builds. Those need a live server. What it does prove is that the DDL is
valid PostgreSQL 16 and that the two definitions of the schema agree.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import pglast
from pglast import ast
from sqlalchemy.dialects import postgresql
from sqlalchemy.schema import CreateTable

from thsync.schema import metadata

#: Repo-root `supabase/migrations`, not `sync/migrations`.
#:
#: Supabase branching applies whatever is in that directory when it builds a
#: preview branch and when it deploys the production branch. Keeping the
#: service's DDL anywhere else would mean every branch came up with an empty
#: database while the tests stayed green.
MIGRATIONS = Path(__file__).resolve().parents[2] / "supabase" / "migrations"

#: `YYYYMMDDHHmmss_name.sql`. The runner applies files in filename order, so a
#: file that does not sort by timestamp would be applied at the wrong moment.
_FILENAME = re.compile(r"^\d{14}_[a-z0-9_]+\.sql$")


def _sql() -> str:
    return "\n".join(path.read_text() for path in sorted(MIGRATIONS.glob("*.sql")))


def _type_of(column: ast.ColumnDef) -> str:
    """A column's type as PostgreSQL itself names it, with any length.

    `names` is schema-qualified — `pg_catalog.int8` — and only the last part
    identifies the type. Length modifiers are kept because `varchar(128)` and
    `varchar(256)` are genuinely different columns, and dropping them would
    make this test pass on exactly the drift it exists to catch.
    """
    type_name = column.typeName
    assert type_name is not None, column.colname
    names = type_name.names or ()
    base = str(names[-1].sval)
    mods: list[str] = []
    for mod in type_name.typmods or ():
        if isinstance(mod, ast.A_Const) and isinstance(mod.val, ast.Integer):
            mods.append(str(mod.val.ival))
    return f"{base}({','.join(mods)})" if mods else base


def _relname(statement: ast.CreateStmt) -> str:
    """The table a CREATE TABLE names. Always present; narrowing for mypy."""
    relation = statement.relation
    assert relation is not None and relation.relname is not None
    return str(relation.relname)


def _colname(column: ast.ColumnDef) -> str:
    assert column.colname is not None
    return str(column.colname)


def _tables(sql: str) -> dict[str, dict[str, str]]:
    """Every `CREATE TABLE` in `sql`, as `{table: {column: type}}`."""
    found: dict[str, dict[str, str]] = {}
    for raw in pglast.parse_sql(sql):
        statement = raw.stmt
        if not isinstance(statement, ast.CreateStmt):
            continue
        columns = {
            _colname(element): _type_of(element)
            for element in statement.tableElts or ()
            if isinstance(element, ast.ColumnDef)
        }
        found[_relname(statement)] = columns
    return found


def _primary_keys(sql: str) -> dict[str, set[str]]:
    keys: dict[str, set[str]] = {}
    for raw in pglast.parse_sql(sql):
        statement = raw.stmt
        if not isinstance(statement, ast.CreateStmt):
            continue
        columns: set[str] = set()
        for element in statement.tableElts or ():
            if isinstance(element, ast.Constraint):
                if element.contype == pglast.enums.parsenodes.ConstrType.CONSTR_PRIMARY:
                    columns |= {key.sval for key in element.keys or ()}
            elif isinstance(element, ast.ColumnDef):
                for constraint in element.constraints or ():
                    if (
                        constraint.contype
                        == pglast.enums.parsenodes.ConstrType.CONSTR_PRIMARY
                    ):
                        columns.add(_colname(element))
        keys[_relname(statement)] = columns
    return keys


def _schema_ddl() -> str:
    """The `MetaData` as PostgreSQL DDL, for the same parser to read."""
    # SQLAlchemy does not annotate `dialect()`, and strict mode refuses an
    # untyped call rather than inferring Any.
    dialect: Any = postgresql.dialect()  # type: ignore[no-untyped-call]
    return "\n".join(
        f"{CreateTable(table).compile(dialect=dialect)};"
        for table in metadata.sorted_tables
    )


def test_migration_filenames_follow_the_convention() -> None:
    files = sorted(MIGRATIONS.glob("*.sql"))
    assert files, "no migrations found"
    for path in files:
        assert _FILENAME.match(path.name), path.name


def test_migrations_do_not_open_their_own_transaction() -> None:
    """The runner wraps each file; a BEGIN here would commit half of it early."""
    for path in sorted(MIGRATIONS.glob("*.sql")):
        body = path.read_text().upper()
        assert not re.search(r"^\s*BEGIN\b", body, re.MULTILINE), path.name
        assert not re.search(r"^\s*COMMIT\b", body, re.MULTILINE), path.name


def test_every_migration_is_valid_postgresql() -> None:
    """Parsed by libpg_query — PostgreSQL's own grammar, not an approximation."""
    for path in sorted(MIGRATIONS.glob("*.sql")):
        # Raises ParseError, which carries the same message the server would
        # give, including the character offset.
        assert pglast.parse_sql(path.read_text()) is not None, path.name


def test_the_migrations_declare_exactly_the_tables_the_code_uses() -> None:
    assert set(_tables(_sql())) == set(metadata.tables)


def test_every_column_and_type_agrees() -> None:
    """The check the old regex version could not make.

    Both sides are canonicalised by the PostgreSQL parser first, so this
    compares `timestamptz` to `TIMESTAMP WITH TIME ZONE` correctly rather than
    reporting a difference that is only spelling.
    """
    in_migration = _tables(_sql())
    in_code = _tables(_schema_ddl())

    assert set(in_migration) == set(in_code)
    for table, columns in in_migration.items():
        assert columns == in_code[table], (
            f"{table}: the migration and thsync.schema disagree. "
            f"migration={columns} code={in_code[table]}"
        )


def test_primary_keys_agree() -> None:
    in_migration = _primary_keys(_sql())
    in_code = _primary_keys(_schema_ddl())
    assert in_migration == in_code


def _defaults(sql: str) -> dict[tuple[str, str], str]:
    """`{(table, column): default}` for every column that has one."""
    found: dict[tuple[str, str], str] = {}
    for raw in pglast.parse_sql(sql):
        statement = raw.stmt
        if not isinstance(statement, ast.CreateStmt):
            continue
        for element in statement.tableElts or ():
            if not isinstance(element, ast.ColumnDef):
                continue
            for constraint in element.constraints or ():
                if (
                    constraint.contype
                    != pglast.enums.parsenodes.ConstrType.CONSTR_DEFAULT
                ):
                    continue
                found[(_relname(statement), _colname(element))] = _render(
                    constraint.raw_expr
                )
    return found


def _render(node: ast.Node | None) -> str:
    """A default expression as a comparable string.

    Only the forms that appear in this schema are decoded. Anything else falls
    back to the node's own repr, which still compares equal when both sides
    say the same thing and still fails loudly when they do not.
    """
    if isinstance(node, ast.A_Const):
        value = node.val
        if isinstance(value, ast.Integer):
            return str(value.ival)
        if isinstance(value, ast.String):
            return str(value.sval)
        if isinstance(value, ast.Boolean):
            return "true" if value.boolval else "false"
    if isinstance(node, ast.TypeCast):
        return _render(node.arg)
    return str(node)


def test_column_defaults_agree_and_are_valid_for_their_type() -> None:
    """Catches a default that is only valid on the database nobody deploys to.

    `server_default=text("0")` on a Boolean compiles to `DEFAULT 0`, which
    SQLite accepts and PostgreSQL rejects outright. A suite that runs on SQLite
    cannot see that, so the two definitions are compared instead: the migration
    is written for Postgres, so agreeing with it is the check.
    """
    assert _defaults(_sql()) == _defaults(_schema_ddl())
