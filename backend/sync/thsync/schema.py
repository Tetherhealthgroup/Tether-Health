"""The tables, as SQLAlchemy Core.

**Core, not the ORM.** The ORM's value is identity mapping and change tracking
across a long-lived object graph, and there is no graph here: a request loads
whole area bundles, writes them, and forgets them. Core keeps the SQL in view;
`thsync.repository` keeps it in one place.

**The migrations are the production source of truth**, not this file. The sync
tables are created by `supabase/migrations/202610180001_sync_tables.sql`, with
row-level security, column grants and triggers this file does not describe.
These table objects exist so that SQLite test databases can be created without
running Postgres DDL, and so that queries are composed instead of concatenated.
`tests/test_migration_matches_schema.py` compares the two and fails when they
drift.

**No tombstones.** A programme's sync rows are removed only by deleting its
enrolment (the foreign key cascades) or by account deletion, both of which go
through the API. Other devices learn about a removed programme from the list of
current programmes every pull carries (`thsync.repository.pull_since`), so no
row is kept to announce it.

`enrolments` is described here for reading only. It belongs to the API's
schema; this service reads the caller's own rows (through row-level security on
Postgres) to find the enrolment a programme's data hangs off, and never writes
it. Only the columns read are listed, and the schema test checks them against
the enrolments migration.

Two constraints in the migrations are left out here because SQLite has nothing
to point them at: `sync_account.user_id` → `auth.users(id)` and
`sync_area.programme_code` → `programmes(code)`. The wire format restricts
programme codes to the same eleven values (`thsync.wire.PROGRAMME_CODES`).
"""

from __future__ import annotations

from typing import Final

from sqlalchemy import (
    JSON,
    BigInteger,
    Column,
    DateTime,
    ForeignKeyConstraint,
    Index,
    Integer,
    MetaData,
    Table,
    Text,
    UniqueConstraint,
    Uuid,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB

__all__ = [
    "SYNC_TABLES",
    "enrolments",
    "metadata",
    "sync_account",
    "sync_answer",
    "sync_area",
    "sync_lapse",
]

metadata = MetaData()

#: `jsonb` on Postgres, a JSON-encoded TEXT column on SQLite. Nothing queries
#: inside these documents — they are opaque payloads — so the variant buys
#: storage compactness and a validity check at write time, not indexing.
_Json = JSON().with_variant(JSONB(), "postgresql")

#: `timestamptz` on Postgres. SQLite has no such type and hands back naive
#: datetimes; `thsync.repository` re-attaches UTC on read rather than trusting
#: the driver, because a naive timestamp that silently means local time is the
#: kind of bug that only shows up in one timezone.
_Timestamp = DateTime(timezone=True)

#: Native `uuid` on Postgres, 32 hex characters on SQLite.
_UserId = Uuid(as_uuid=True)

enrolments = Table(
    "enrolments",
    metadata,
    Column("id", _UserId, primary_key=True),
    Column("user_id", _UserId, nullable=False),
    Column("programme_code", Text, nullable=False),
    # focus, learn_only, paused or left. A left programme's sync data stays,
    # read-only: has_consent() is false for it, so the write policies refuse.
    Column("status", Text, nullable=False),
    UniqueConstraint("user_id", "programme_code"),
)

sync_account = Table(
    "sync_account",
    metadata,
    Column("user_id", _UserId, primary_key=True),
    # The account's change counter. Every write to any of the account's areas
    # takes the next value, which is what makes a single integer cursor able to
    # describe "everything I have seen" across independently-versioned areas.
    # Per-account rather than global: a global sequence would leak the
    # service's total write rate into every client's cursor.
    Column("change_seq", BigInteger, nullable=False, server_default=text("0")),
    # Set by the database (defaults and the updated_at trigger). The service
    # holds no write grant on either.
    Column("created_at", _Timestamp, nullable=False, server_default=func.now()),
    Column("updated_at", _Timestamp, nullable=False, server_default=func.now()),
)

sync_area = Table(
    "sync_area",
    metadata,
    Column("user_id", _UserId, primary_key=True),
    Column("enrolment_id", _UserId, nullable=False),
    Column("programme_code", Text, primary_key=True),
    # Monotonic per area. This, not the account cursor, is what a push is
    # checked against — see `thsync.repository.push_bundles`.
    Column("revision", BigInteger, nullable=False),
    Column("change_seq", BigInteger, nullable=False),
    Column("updated_at", _Timestamp, nullable=False, server_default=func.now()),
    ForeignKeyConstraint(["user_id"], ["sync_account.user_id"], ondelete="CASCADE"),
    # "Delete now" on an enrolment removes its sync data with it.
    ForeignKeyConstraint(["enrolment_id"], ["enrolments.id"], ondelete="CASCADE"),
    UniqueConstraint("enrolment_id", name="sync_area_enrolment_key"),
    # Every read in this service is "one account, changed since N". The index
    # leads with user_id for that reason, and because a query that could scan
    # across accounts is a query that could return another person's row.
    Index("sync_area_change_seq_idx", "user_id", "change_seq"),
)

sync_answer = Table(
    "sync_answer",
    metadata,
    Column("user_id", _UserId, primary_key=True),
    Column("programme_code", Text, primary_key=True),
    # Bare screen id. The `programme/` prefix the client sends is validated and
    # then dropped, because keeping it would store the programme twice — in
    # the key and in the column — and a row where those two disagreed would be
    # an answer belonging to two programmes at once.
    Column("screen_id", Text, primary_key=True),
    # A cleared screen is stored as `{}`: there is no delete grant, and
    # replacing the payload is what makes the old content really gone.
    Column("payload", _Json, nullable=False),
    Column("updated_at", _Timestamp, nullable=False, server_default=func.now()),
    ForeignKeyConstraint(
        ["user_id", "programme_code"],
        ["sync_area.user_id", "sync_area.programme_code"],
        ondelete="CASCADE",
    ),
)

sync_lapse = Table(
    "sync_lapse",
    metadata,
    Column("user_id", _UserId, primary_key=True),
    Column("programme_code", Text, primary_key=True),
    # Position in the client's list. Lapses are append-only: a stored ordinal
    # is never rewritten, and new lapses take the next ordinals.
    Column("ordinal", Integer, primary_key=True),
    Column("at", _Timestamp, nullable=False),
    Column("severity", Text, nullable=False, server_default=text("''")),
    Column("context", _Json, nullable=False, server_default=text("'[]'")),
    ForeignKeyConstraint(
        ["user_id", "programme_code"],
        ["sync_area.user_id", "sync_area.programme_code"],
        ondelete="CASCADE",
    ),
)

#: The tables this service writes and the migration creates.
SYNC_TABLES: Final = frozenset({"sync_account", "sync_area", "sync_answer", "sync_lapse"})
