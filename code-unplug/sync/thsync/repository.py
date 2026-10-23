"""Reads and writes, and the sync policy they implement.

# The unit of sync is one programme

A person's `TetherSession` is one JSON document on the phone, and the obvious
server design is to store that document and version it. This does not do that,
and the reason is not performance.

42 CFR Part 2 treats a substance-use programme's record as segregated: consent
to disclose one programme is not consent to disclose another, and a person may
revoke one without touching the rest. A whole-document design cannot express
that. Revoking one programme means rewriting the document, which means every
other programme's bytes are read, rewritten, and re-versioned by an operation
that had nothing to do with them; and a document-level conflict means two
programmes the person edited on two phones cannot both survive. So the row here
is `(account_id, area_id)`, answers and lapses hang off it, and every operation
in this module names exactly one programme at a time.

# The conflict policy

**Per-area optimistic concurrency on a monotonic `revision`, with conflicts
returned to the client and never merged by the server.**

A push sends, for each area, the `base_revision` it last saw. If the server's
current revision for that area differs, the push for *that area* is refused and
the server's current bundle is returned alongside it; the areas that did match
are still applied. The client decides what happens next.

The rejected alternatives, and why:

* *Last-writer-wins on the document.* A phone that has been offline for a week
  overwrites a week of another device's work, silently. For chip selections
  this is annoying; for a lapse history it is the destruction of a clinical
  record with no trace that it happened.
* *Last-writer-wins per area.* Better, still wrong for the same reason at
  smaller scale, and it makes the outcome depend on which phone happened to
  reach the server second.
* *Field-level merge on the server.* This is the tempting one, because most of
  these conflicts are trivially mergeable. It is refused because the server
  cannot ask. Two devices holding different answers to the same screen is a
  question about what the person actually meant, and the client is the only
  place where they can be asked — and where the merge, if one is chosen, is
  visible to them.

`base_revision: null` means "I believe the server has never held this area". If
the server does hold it, that is a conflict too (`unknown-to-server` when the
reverse happens), rather than a create that overwrites.

# The cursor

`sync_account.change_seq` is a per-account counter. Each write to any of the
account's areas takes the next value and stamps it on the area row, so one
integer can describe "I have seen everything up to here" across areas that are
versioned independently. A pull returns every area whose `change_seq` exceeds
the cursor.

The filtered pull is the subtle case; see [pull_since].
"""

from __future__ import annotations

from collections.abc import Iterable, Sequence
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import delete, func, insert, select, update
from sqlalchemy.engine import Connection, Row

from thsync.logs import log
from thsync.schema import sync_account, sync_answer, sync_area, sync_lapse
from thsync.wire import AreaBundle, Conflict, Enrolment, Lapse, PushBundle, ScreenAnswers, Sharing

__all__ = [
    "PullResult",
    "PushResult",
    "RevokeResult",
    "current_cursor",
    "erase_account",
    "load_bundle",
    "pull_since",
    "push_bundles",
    "revoke_area",
    "utcnow",
]


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


@dataclass(frozen=True, slots=True)
class PullResult:
    cursor: int
    bundles: list[AreaBundle]


@dataclass(frozen=True, slots=True)
class PushResult:
    cursor: int
    applied: list[str]
    conflicts: list[Conflict]


@dataclass(frozen=True, slots=True)
class RevokeResult:
    revision: int
    cursor: int
    #: False when the programme was already revoked. The endpoint still answers
    #: 200 — asking twice for something to be destroyed must not look like a
    #: failure — but nothing is written and no revision is spent.
    changed: bool


# --- Account bookkeeping -----------------------------------------------------


def current_cursor(connection: Connection, account_id: str) -> int:
    """The account's change counter, or 0 if it has never written."""
    value = connection.execute(
        select(sync_account.c.change_seq).where(sync_account.c.account_id == account_id)
    ).scalar_one_or_none()
    return int(value) if value is not None else 0


def _ensure_account(connection: Connection, account_id: str, now: datetime) -> None:
    exists = connection.execute(
        select(sync_account.c.account_id).where(sync_account.c.account_id == account_id)
    ).scalar_one_or_none()
    if exists is None:
        connection.execute(
            insert(sync_account).values(
                account_id=account_id, change_seq=0, created_at=now, updated_at=now
            )
        )


def _next_seq(connection: Connection, account_id: str, now: datetime) -> int:
    """Claims the next change number for [account_id].

    `UPDATE … SET change_seq = change_seq + 1` then a read, rather than reading
    and writing back a computed value: the increment happens in the database,
    so two concurrent pushes for one account serialise on the row lock instead
    of both claiming the same number. Written as two statements rather than one
    `RETURNING` so that it behaves identically on SQLite builds without it —
    the row is already locked by the update, so the read cannot race.
    """
    connection.execute(
        update(sync_account)
        .where(sync_account.c.account_id == account_id)
        .values(change_seq=sync_account.c.change_seq + 1, updated_at=now)
    )
    return current_cursor(connection, account_id)


# --- Reading -----------------------------------------------------------------


def load_bundle(connection: Connection, account_id: str, area_id: str) -> AreaBundle | None:
    """One programme's bundle, or None if the account has no such area."""
    row = connection.execute(
        select(sync_area).where(
            sync_area.c.account_id == account_id, sync_area.c.area_id == area_id
        )
    ).one_or_none()
    if row is None:
        return None
    return _bundle_from(connection, account_id, row)


def pull_since(
    connection: Connection,
    account_id: str,
    cursor: int,
    areas: Sequence[str] | None,
) -> PullResult:
    """Bundles changed after [cursor], and the cursor to ask from next time.

    The returned cursor is the interesting part when [areas] filters the
    result. Returning the account's current counter would be wrong: changes to
    the programmes the client filtered out were never sent, and a later
    unfiltered pull from that cursor would skip them forever. Returning the
    cursor unchanged would be safe and useless — the client would re-download
    the same bundles on every sync.

    So the cursor returned is the highest value below which nothing was
    withheld: one less than the smallest `change_seq` that was filtered out, or
    the account's current counter if nothing was. The client may be handed
    bundles numbered above that watermark, and will be handed them again next
    time; a duplicate bundle is idempotent, a skipped one is data loss, and the
    asymmetry is the whole design.
    """
    changed = connection.execute(
        select(sync_area.c.area_id, sync_area.c.change_seq).where(
            sync_area.c.account_id == account_id, sync_area.c.change_seq > cursor
        )
    ).all()

    wanted = set(areas) if areas is not None else None
    withheld = [row.change_seq for row in changed if wanted is not None and row.area_id not in wanted]
    selected = [row.area_id for row in changed if wanted is None or row.area_id in wanted]

    next_cursor = min(withheld) - 1 if withheld else current_cursor(connection, account_id)

    bundles: list[AreaBundle] = []
    for area_id in sorted(selected):
        bundle = load_bundle(connection, account_id, area_id)
        if bundle is not None:
            bundles.append(bundle)

    log.info(
        "pull account=%s from=%d to=%d areas=%d filtered=%s",
        account_id,
        cursor,
        next_cursor,
        len(bundles),
        wanted is not None,
    )
    return PullResult(cursor=next_cursor, bundles=bundles)


def _bundle_from(connection: Connection, account_id: str, row: Row[Any]) -> AreaBundle:
    area_id: str = row.area_id
    if row.revoked:
        # Nothing is loaded for a revoked area, because there is nothing left
        # to load. The empty bundle is the instruction to delete.
        return AreaBundle(area=area_id, revision=int(row.revision), revoked=True)

    answer_rows = connection.execute(
        select(sync_answer.c.screen_id, sync_answer.c.payload).where(
            sync_answer.c.account_id == account_id, sync_answer.c.area_id == area_id
        )
    ).all()
    lapse_rows = connection.execute(
        select(sync_lapse.c.at, sync_lapse.c.severity, sync_lapse.c.context)
        .where(sync_lapse.c.account_id == account_id, sync_lapse.c.area_id == area_id)
        .order_by(sync_lapse.c.ordinal)
    ).all()

    return AreaBundle(
        area=area_id,
        revision=int(row.revision),
        revoked=False,
        enrolment=Enrolment(
            status=row.enrolment_status or "none",
            hidden=bool(row.enrolment_hidden),
            joinedOn=_as_utc(row.joined_on),
            sharing=Sharing(
                totalsAndAdherence=bool(row.share_totals_and_adherence),
                notes=bool(row.share_notes),
                recipient=row.share_recipient,
            ),
        ),
        # Re-attached to the full `areaId/screenId` form the client files them
        # under. The prefix is `area_id` from this row, so a stored answer can
        # only ever come back out attributed to the programme it is stored in.
        answers={
            f"{area_id}/{answer.screen_id}": ScreenAnswers.model_validate(answer.payload)
            for answer in answer_rows
        },
        lapses=[
            Lapse(
                at=_as_utc(lapse.at) or utcnow(),
                severity=lapse.severity,
                context=list(lapse.context or []),
            )
            for lapse in lapse_rows
        ],
    )


def _as_utc(value: datetime | None) -> datetime | None:
    """Reads a stored instant as UTC.

    Postgres hands back an aware datetime from `timestamptz`; SQLite hands back
    a naive one, because it has no timestamp type at all and the driver is
    parsing a string. Everything written here was converted to UTC first, so
    attaching UTC to a naive value restores it — and doing it in one place
    means no caller has to know which database it is talking to.
    """
    if value is None:
        return None
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


# --- Writing -----------------------------------------------------------------


def push_bundles(
    connection: Connection, account_id: str, bundles: Iterable[PushBundle]
) -> PushResult:
    """Applies each bundle whose `base_revision` matches, reporting the rest.

    Per-area, not all-or-nothing: a conflict on one programme must not block a
    write to another, or the segregation is only skin deep — one contested
    programme would hold every other programme's sync hostage.
    """
    now = utcnow()
    _ensure_account(connection, account_id, now)

    applied: list[str] = []
    conflicts: list[Conflict] = []

    for bundle in bundles:
        existing = connection.execute(
            select(sync_area.c.revision, sync_area.c.revoked).where(
                sync_area.c.account_id == account_id, sync_area.c.area_id == bundle.area
            )
        ).one_or_none()

        server_revision = int(existing.revision) if existing is not None else None
        if server_revision != bundle.base_revision:
            conflicts.append(
                Conflict(
                    area=bundle.area,
                    reason="stale-revision" if existing is not None else "unknown-to-server",
                    base_revision=bundle.base_revision,
                    server_revision=server_revision,
                    server=load_bundle(connection, account_id, bundle.area),
                )
            )
            continue

        seq = _next_seq(connection, account_id, now)
        _write_bundle(connection, account_id, bundle, seq, now, existing is not None)
        applied.append(bundle.area)

    cursor = current_cursor(connection, account_id)
    log.info(
        "push account=%s applied=%d conflicts=%d cursor=%d",
        account_id,
        len(applied),
        len(conflicts),
        cursor,
    )
    return PushResult(cursor=cursor, applied=applied, conflicts=conflicts)


def _write_bundle(
    connection: Connection,
    account_id: str,
    bundle: PushBundle,
    seq: int,
    now: datetime,
    exists: bool,
) -> None:
    """Replaces one programme's stored record with [bundle].

    Whole-bundle replacement rather than a per-screen delta. A delta protocol
    would need a revision per screen and per lapse, and would then have to
    answer what a conflict on one screen means for the rest of the programme —
    while the client already holds the whole programme in memory and sends it
    for a few kilobytes. The area is the unit of consent, so it is also the
    unit of the write.

    A revoked area being pushed to again is a re-enrolment: the person joined
    the programme a second time. `revoked` goes back to false and the revision
    continues upward rather than restarting, so a device that saw the tombstone
    can tell the new record from the old one.
    """
    enrolment = bundle.enrolment
    assert enrolment is not None  # PushBundle validates this.

    values: dict[str, Any] = {
        "revision": (bundle.base_revision or 0) + 1,
        "change_seq": seq,
        "revoked": False,
        "enrolment_status": enrolment.status,
        "enrolment_hidden": enrolment.hidden,
        "joined_on": _to_utc(enrolment.joined_on),
        "share_totals_and_adherence": enrolment.sharing.totals_and_adherence,
        "share_notes": enrolment.sharing.notes,
        "share_recipient": enrolment.sharing.recipient,
        "updated_at": now,
    }

    if exists:
        connection.execute(
            update(sync_area)
            .where(sync_area.c.account_id == account_id, sync_area.c.area_id == bundle.area)
            .values(**values)
        )
    else:
        connection.execute(
            insert(sync_area).values(account_id=account_id, area_id=bundle.area, **values)
        )

    _delete_area_content(connection, account_id, bundle.area)

    screens = bundle.screen_answers()
    if screens:
        connection.execute(
            insert(sync_answer),
            [
                {
                    "account_id": account_id,
                    "area_id": bundle.area,
                    "screen_id": screen_id,
                    "payload": answers.model_dump(by_alias=True),
                    "updated_at": now,
                }
                for screen_id, answers in screens.items()
            ],
        )

    if bundle.lapses:
        connection.execute(
            insert(sync_lapse),
            [
                {
                    "account_id": account_id,
                    "area_id": bundle.area,
                    "ordinal": ordinal,
                    "at": _to_utc(lapse.at),
                    "severity": lapse.severity,
                    "context": list(lapse.context),
                }
                for ordinal, lapse in enumerate(bundle.lapses)
            ],
        )


def _to_utc(value: datetime | None) -> datetime | None:
    """Normalises to UTC before storage.

    The wire types require an aware datetime, so this never has to guess. It
    converts rather than merely asserts because SQLite would otherwise store
    the local-time digits of a `+05:30` instant and read them back as UTC.
    """
    return None if value is None else value.astimezone(timezone.utc)


def _delete_area_content(connection: Connection, account_id: str, area_id: str) -> None:
    """Removes one programme's answers and lapses. Leaves the area row.

    Written out rather than left to `ON DELETE CASCADE`, even though the
    cascade exists and is enabled on both databases. The cascade is a backstop;
    this is the statement somebody can be shown when they ask what revocation
    does. Both are scoped by `account_id` — a delete in this service is never
    keyed on `area_id` alone.
    """
    connection.execute(
        delete(sync_answer).where(
            sync_answer.c.account_id == account_id, sync_answer.c.area_id == area_id
        )
    )
    connection.execute(
        delete(sync_lapse).where(
            sync_lapse.c.account_id == account_id, sync_lapse.c.area_id == area_id
        )
    )


def revoke_area(connection: Connection, account_id: str, area_id: str) -> RevokeResult | None:
    """Destroys one programme's data, leaving the others untouched.

    Returns None when the account has no such area — a 404, rather than a
    silent success, because "there was nothing there" and "it is gone now" are
    different answers to give somebody who has just revoked consent.

    This is a hard delete. The answers and lapses rows are removed; what
    survives is the area row, carrying its id, a bumped revision, and a
    `revoked` flag, so that the person's other device learns on its next pull
    that this programme is to be deleted there too. See `thsync.schema` for why
    that residue is judged acceptable and what removes it.
    """
    now = utcnow()
    existing = connection.execute(
        select(sync_area.c.revision, sync_area.c.revoked).where(
            sync_area.c.account_id == account_id, sync_area.c.area_id == area_id
        )
    ).one_or_none()
    if existing is None:
        return None

    if existing.revoked:
        return RevokeResult(
            revision=int(existing.revision),
            cursor=current_cursor(connection, account_id),
            changed=False,
        )

    _delete_area_content(connection, account_id, area_id)
    seq = _next_seq(connection, account_id, now)
    revision = int(existing.revision) + 1
    connection.execute(
        update(sync_area)
        .where(sync_area.c.account_id == account_id, sync_area.c.area_id == area_id)
        .values(
            revision=revision,
            change_seq=seq,
            revoked=True,
            # Cleared, not kept for audit. An enrolment date and a sharing
            # recipient are the record; "kept for audit" is how a hard delete
            # becomes a soft one.
            enrolment_status=None,
            enrolment_hidden=None,
            joined_on=None,
            share_totals_and_adherence=None,
            share_notes=None,
            share_recipient=None,
            updated_at=now,
        )
    )
    log.info("revoked account=%s area=%s revision=%d", account_id, area_id, revision)
    return RevokeResult(revision=revision, cursor=seq, changed=True)


def erase_account(connection: Connection, account_id: str) -> int:
    """Removes everything held for [account_id]. Returns the areas destroyed.

    The counterpart of `TetherSession.deleteEverything`, whose contract is that
    deletion is "completed rather than hidden". So this takes the tombstones
    too: after it there is no row anywhere that says this account existed, and
    a subsequent pull looks exactly like a pull from a phone that has never
    synced. Nothing is left for another device to reconstruct from, which is
    also the reason this cannot be built out of repeated single-area
    revocations.

    Idempotent, because the client calls it from a path where a retry after a
    dropped connection must not report failure to somebody who has been told
    their data is gone.
    """
    areas = connection.execute(
        select(func.count()).select_from(sync_area).where(sync_area.c.account_id == account_id)
    ).scalar_one()

    # Children first, explicitly, in case this ever runs somewhere the cascade
    # is not enforced — SQLite's `PRAGMA foreign_keys` is per-connection and
    # off by default, which is exactly the kind of setting that is on in the
    # test suite and off in some future script.
    connection.execute(delete(sync_lapse).where(sync_lapse.c.account_id == account_id))
    connection.execute(delete(sync_answer).where(sync_answer.c.account_id == account_id))
    connection.execute(delete(sync_area).where(sync_area.c.account_id == account_id))
    connection.execute(delete(sync_account).where(sync_account.c.account_id == account_id))

    log.info("erased account=%s areas=%d", account_id, areas)
    return int(areas)
