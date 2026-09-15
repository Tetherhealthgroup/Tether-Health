"""The tables, as SQLAlchemy Core.

**Core, not the ORM.** The ORM's value is identity mapping and change tracking
across a long-lived object graph, and there is no graph here: a request loads
whole area bundles, replaces them, and forgets them. What the ORM would add
instead is a second place where a `DELETE` might or might not cascade depending
on relationship configuration, and revocation under 42 CFR Part 2 is the one
operation in this service that has to be readable as a statement rather than
inferred from a mapping. Core keeps the SQL in view; `thsync.repository` keeps
it in one place.

**The migrations are the production source of truth**, not this file. These
table objects exist so that SQLite test databases can be created without
running Postgres DDL, and so that queries are composed instead of concatenated.
`tests/test_migration_matches_schema.py` compares the two and fails when they
drift.

A note on the tombstone. `sync_area.revoked` leaves one row behind after a
programme is destroyed, holding the area id, a revision and a timestamp — and
nothing else: no enrolment, no answers, no lapses. Keeping it is a real
trade-off, because the row still says "this account once had a tobacco
bundle". It is kept because the other device in the sync pair has a full copy
of that programme, and without a tombstone to pull there is nothing that tells
it to delete: the revocation would apply to the server only, which is the
opposite of what the person asked for. `DELETE /v1/sync/account` removes the
tombstones too, so a full erasure leaves nothing at all.
"""

from __future__ import annotations

from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    ForeignKeyConstraint,
    Index,
    Integer,
    JSON,
    MetaData,
    String,
    Table,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB

__all__ = ["metadata", "sync_account", "sync_area", "sync_answer", "sync_lapse"]

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

sync_account = Table(
    "sync_account",
    metadata,
    Column("account_id", String(128), primary_key=True),
    # The account's change counter. Every write to any of the account's areas
    # takes the next value, which is what makes a single integer cursor able to
    # describe "everything I have seen" across independently-versioned areas.
    # Per-account rather than global: a global sequence would leak the
    # service's total write rate into every client's cursor, and would make one
    # noisy account advance everybody else's numbers.
    Column("change_seq", BigInteger, nullable=False, server_default=text("0")),
    Column("created_at", _Timestamp, nullable=False),
    Column("updated_at", _Timestamp, nullable=False),
)

sync_area = Table(
    "sync_area",
    metadata,
    Column("account_id", String(128), primary_key=True),
    Column("area_id", String(64), primary_key=True),
    # Monotonic per area. This, not the account cursor, is what a push is
    # checked against — see `thsync.repository.push_bundles`.
    Column("revision", BigInteger, nullable=False),
    Column("change_seq", BigInteger, nullable=False),
    Column("revoked", Boolean, nullable=False, server_default=text("0")),
    # Null on a revoked area. Nullable rather than a separate table because the
    # enrolment is one-to-one with the area and splitting it would mean a
    # revocation had two rows to clear instead of one.
    Column("enrolment_status", String(16), nullable=True),
    Column("enrolment_hidden", Boolean, nullable=True),
    Column("joined_on", _Timestamp, nullable=True),
    Column("share_totals_and_adherence", Boolean, nullable=True),
    Column("share_notes", Boolean, nullable=True),
    Column("share_recipient", String(256), nullable=True),
    Column("updated_at", _Timestamp, nullable=False),
    ForeignKeyConstraint(
        ["account_id"], ["sync_account.account_id"], ondelete="CASCADE"
    ),
    # Every read in this service is "one account, changed since N". The index
    # leads with account_id for that reason, and because a query that could
    # scan across accounts is a query that could return another person's row.
    Index("sync_area_change_seq_idx", "account_id", "change_seq"),
)

sync_answer = Table(
    "sync_answer",
    metadata,
    Column("account_id", String(128), primary_key=True),
    Column("area_id", String(64), primary_key=True),
    # Bare screen id. The `areaId/` prefix the client sends is validated and
    # then dropped, because keeping it would store the area twice — in the key
    # and in the column — and a row where those two disagreed would be an
    # answer belonging to two programmes at once.
    Column("screen_id", String(64), primary_key=True),
    Column("payload", _Json, nullable=False),
    Column("updated_at", _Timestamp, nullable=False),
    ForeignKeyConstraint(
        ["account_id", "area_id"],
        ["sync_area.account_id", "sync_area.area_id"],
        ondelete="CASCADE",
    ),
)

sync_lapse = Table(
    "sync_lapse",
    metadata,
    Column("account_id", String(128), primary_key=True),
    Column("area_id", String(64), primary_key=True),
    # Position in the client's list. A surrogate key would need a sequence and
    # would still not preserve order; the client holds lapses as an ordered
    # list and replaces the whole list on every push, so the index *is* the
    # identity and the write stays deterministic.
    Column("ordinal", Integer, primary_key=True),
    Column("at", _Timestamp, nullable=False),
    Column("severity", String(64), nullable=False),
    Column("context", _Json, nullable=False),
    ForeignKeyConstraint(
        ["account_id", "area_id"],
        ["sync_area.account_id", "sync_area.area_id"],
        ondelete="CASCADE",
    ),
)
