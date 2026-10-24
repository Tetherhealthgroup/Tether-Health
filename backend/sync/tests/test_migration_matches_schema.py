"""The sync tables migration and `thsync.schema` must describe the same tables.

The migration is what production runs; the `MetaData` is what the SQLite tests
run against and what every query is built from. Nothing else enforces that
they agree, and the failure mode if they do not is the worst kind: a green test
suite and a column that does not exist on the server.

The migration is `supabase/migrations/202610180001_sync_tables.sql`. It is
named here rather than discovered, so moving or replacing it fails this file
instead of silently comparing against nothing.

**How types are compared without a Postgres server.** Comparing types does not
need a server, only PostgreSQL's parser, and that is available as a library:
`pglast` wraps `libpg_query`, which is the real `gram.y` lifted out of the
server source. Both sides are put through it, so the migration's `timestamptz`
and SQLAlchemy's `TIMESTAMP WITH TIME ZONE` compare equal, as do
`bigint`/`int8`, while `text` and `varchar(128)` do not. Behaviour (policies,
grants, cascades on a real server) is the PostgreSQL suite's job
(`test_postgres.py`).
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import pglast
from pglast import ast
from sqlalchemy.dialects import postgresql
from sqlalchemy.schema import CreateTable

from thsync.schema import SYNC_TABLES, metadata

#: Repo-root `supabase/migrations`, where Supabase applies migrations from.
MIGRATIONS = Path(__file__).resolve().parents[3] / "supabase" / "migrations"

#: The migration that creates the sync tables.
SYNC_MIGRATION = MIGRATIONS / "202610180001_sync_tables.sql"

#: The migration that creates `enrolments`, which the service reads.
ENROLMENTS_MIGRATION = MIGRATIONS / "202610170002_enrolments.sql"

#: The repository's migration naming rule: a 12-digit version, then a name.
_FILENAME = re.compile(r"^[0-9]{12}_[a-z0-9_]+\.sql$")


def _sql() -> str:
    return SYNC_MIGRATION.read_text()


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


def _schema_ddl(tables: frozenset[str] = SYNC_TABLES) -> str:
    """The `MetaData` as PostgreSQL DDL, for the same parser to read."""
    # SQLAlchemy does not annotate `dialect()`, and strict mode refuses an
    # untyped call rather than inferring Any.
    dialect: Any = postgresql.dialect()  # type: ignore[no-untyped-call]
    return "\n".join(
        f"{CreateTable(table).compile(dialect=dialect)};"
        for table in metadata.sorted_tables
        if table.name in tables
    )


def test_the_sync_migration_is_the_one_that_creates_the_sync_tables() -> None:
    assert _FILENAME.match(SYNC_MIGRATION.name), SYNC_MIGRATION.name
    assert set(_tables(_sql())) == SYNC_TABLES
    # And no other migration creates them.
    for path in sorted(MIGRATIONS.glob("*.sql")):
        if path != SYNC_MIGRATION:
            assert not set(_tables(path.read_text())) & SYNC_TABLES, path.name


def test_the_sync_migration_is_one_transaction() -> None:
    """Every migration in this repository is wrapped in its own begin/commit."""
    statements = [raw.stmt for raw in pglast.parse_sql(_sql())]
    first, last = statements[0], statements[-1]
    assert isinstance(first, ast.TransactionStmt)
    assert first.kind == pglast.enums.parsenodes.TransactionStmtKind.TRANS_STMT_BEGIN
    assert isinstance(last, ast.TransactionStmt)
    assert last.kind == pglast.enums.parsenodes.TransactionStmtKind.TRANS_STMT_COMMIT
    assert not [s for s in statements[1:-1] if isinstance(s, ast.TransactionStmt)]


def test_every_migration_is_valid_postgresql() -> None:
    """Parsed by libpg_query — PostgreSQL's own grammar, not an approximation."""
    # Every file in the shared directory, not just this service's: a syntax
    # error in any of them fails the same deploy.
    for path in sorted(MIGRATIONS.glob("*.sql")):
        # Raises ParseError, which carries the same message the server would
        # give, including the character offset.
        assert pglast.parse_sql(path.read_text()) is not None, path.name


def test_no_later_migration_changes_a_sync_table_s_columns() -> None:
    """A column added, dropped or retyped elsewhere would bypass this file."""
    changes = {
        pglast.enums.parsenodes.AlterTableType.AT_AddColumn,
        pglast.enums.parsenodes.AlterTableType.AT_DropColumn,
        pglast.enums.parsenodes.AlterTableType.AT_AlterColumnType,
        pglast.enums.parsenodes.AlterTableType.AT_ColumnDefault,
    }
    for path in sorted(MIGRATIONS.glob("*.sql")):
        for raw in pglast.parse_sql(path.read_text()):
            statement = raw.stmt
            if not isinstance(statement, ast.AlterTableStmt):
                continue
            relation = statement.relation
            if relation is None or relation.relname not in SYNC_TABLES:
                continue
            for command in statement.cmds or ():
                assert isinstance(command, ast.AlterTableCmd)
                assert command.subtype not in changes, (path.name, relation.relname)


def test_the_migrations_declare_exactly_the_tables_the_code_writes() -> None:
    assert set(_tables(_sql())) == {
        name for name in metadata.tables if name in SYNC_TABLES
    }


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
    if isinstance(node, ast.FuncCall):
        name = ".".join(str(part.sval) for part in node.funcname or ())
        return f"{name}()" if not node.args else str(node)
    return str(node)


def test_column_defaults_agree_and_are_valid_for_their_type() -> None:
    """Catches a default that is only valid on the database nobody deploys to.

    A default SQLite accepts and PostgreSQL rejects would be invisible to a
    suite that runs on SQLite, so the two definitions are compared instead:
    the migration is written for Postgres, so agreeing with it is the check.
    """
    assert _defaults(_sql()) == _defaults(_schema_ddl())


def _foreign_keys(sql: str) -> set[tuple[str, tuple[str, ...], str, tuple[str, ...], str]]:
    """`(table, columns, referenced table, referenced columns, on delete)`."""
    found: set[tuple[str, tuple[str, ...], str, tuple[str, ...], str]] = set()
    for raw in pglast.parse_sql(sql):
        statement = raw.stmt
        if not isinstance(statement, ast.CreateStmt):
            continue
        table = _relname(statement)
        for element in statement.tableElts or ():
            constraints: list[tuple[tuple[str, ...], ast.Constraint]] = []
            if isinstance(element, ast.Constraint):
                constraints.append(
                    (tuple(str(key.sval) for key in element.fk_attrs or ()), element)
                )
            elif isinstance(element, ast.ColumnDef):
                for constraint in element.constraints or ():
                    constraints.append(((_colname(element),), constraint))
            for columns, constraint in constraints:
                if constraint.contype != pglast.enums.parsenodes.ConstrType.CONSTR_FOREIGN:
                    continue
                target = constraint.pktable
                assert target is not None and target.relname is not None
                found.add(
                    (
                        table,
                        columns,
                        str(target.relname),
                        tuple(str(key.sval) for key in constraint.pk_attrs or ()),
                        str(constraint.fk_del_action),
                    )
                )
    return found


#: Constraints the SQLite stand-in leaves out, because it has no table to point
#: them at (see `thsync.schema`).
_NOT_MIRRORED = {"users", "programmes"}


def test_foreign_keys_and_their_cascades_agree() -> None:
    """Deletion reaches sync data only through these cascades, so they are
    compared exactly, including `on delete`."""
    in_migration = {fk for fk in _foreign_keys(_sql()) if fk[2] not in _NOT_MIRRORED}
    in_code = _foreign_keys(_schema_ddl())
    assert in_migration == in_code
    # The two that make "delete now" and account deletion reach every row.
    assert ("sync_area", ("enrolment_id",), "enrolments", ("id",), "c") in in_code
    assert ("sync_area", ("user_id",), "sync_account", ("user_id",), "c") in in_code


def test_the_enrolment_columns_the_service_reads_exist_with_these_types() -> None:
    in_migration = _tables(ENROLMENTS_MIGRATION.read_text())["enrolments"]
    in_code = _tables(_schema_ddl(frozenset({"enrolments"})))["enrolments"]
    for column, kind in in_code.items():
        assert in_migration.get(column) == kind, column
