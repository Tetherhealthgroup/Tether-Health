"""The `.sql` migrations and `thsync.schema` must describe the same tables.

The migrations are what production runs; the `MetaData` is what the tests run
against and what every query is built from. Nothing enforces that they agree,
and the failure mode if they do not is the worst kind: a green test suite and a
column that does not exist on the server. This compares them structurally —
table names, column names, primary keys — which catches the drift that matters
(a column added to one and not the other) without pretending to parse Postgres
DDL properly.

It cannot check types. `timestamptz` versus SQLAlchemy's `DateTime(timezone=
True)` and `jsonb` versus the JSON variant are unverified here and can only be
verified against a real Postgres server.
"""

from __future__ import annotations

import re
from pathlib import Path

from thsync.schema import metadata

MIGRATIONS = Path(__file__).resolve().parent.parent / "migrations"

_CREATE_TABLE = re.compile(
    r"CREATE TABLE(?:\s+IF NOT EXISTS)?\s+(\w+)\s*\((.*?)\n\);", re.IGNORECASE | re.DOTALL
)
_COLUMN = re.compile(r"^\s{4}(\w+)\s+\w", re.MULTILINE)
_PRIMARY_KEY = re.compile(r"PRIMARY KEY\s*\(([^)]*)\)", re.IGNORECASE)
_INLINE_PRIMARY_KEY = re.compile(r"^\s{4}(\w+)\s+[\w()]+\s+PRIMARY KEY", re.IGNORECASE | re.MULTILINE)

#: `YYYYMMDDHHmmss_name.sql`. The runner applies files in filename order, so a
#: file that does not sort by timestamp would be applied at the wrong moment.
_FILENAME = re.compile(r"^\d{14}_[a-z0-9_]+\.sql$")


def _sql() -> str:
    return "\n".join(path.read_text() for path in sorted(MIGRATIONS.glob("*.sql")))


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


def test_the_migrations_declare_exactly_the_tables_the_code_uses() -> None:
    declared = {match.group(1) for match in _CREATE_TABLE.finditer(_sql())}
    assert declared == set(metadata.tables)


def test_every_column_appears_in_both() -> None:
    for name, body in ((m.group(1), m.group(2)) for m in _CREATE_TABLE.finditer(_sql())):
        table = metadata.tables[name]
        # Constraint lines (`PRIMARY KEY (…)`, `FOREIGN KEY (…)`) are indented
        # four spaces like columns but start with a keyword, so they are
        # excluded by name rather than by a smarter parser.
        in_sql = {
            column
            for column in _COLUMN.findall(body)
            if column.upper() not in {"PRIMARY", "FOREIGN", "UNIQUE", "CHECK", "CONSTRAINT"}
        }
        assert in_sql == set(table.columns.keys()), name


def test_primary_keys_agree() -> None:
    for name, body in ((m.group(1), m.group(2)) for m in _CREATE_TABLE.finditer(_sql())):
        table = metadata.tables[name]
        inline = _INLINE_PRIMARY_KEY.findall(body)
        composite = _PRIMARY_KEY.search(body)
        in_sql = set(inline) | (
            {part.strip() for part in composite.group(1).split(",")} if composite else set()
        )
        assert in_sql == {column.name for column in table.primary_key}, name
