"""Reads and writes, and the sync policy they implement.

# The unit of sync is one programme

42 CFR Part 2 treats a substance-use programme's record as segregated: consent
to disclose one programme is not consent to disclose another, and a person may
revoke one without touching the rest. So the row here is `(user_id,
programme_code)`, answers and lapses hang off it, and every write in this
module names exactly one programme at a time.

A programme's data hangs off the caller's enrolment in that programme
(`sync_area.enrolment_id`). This service never creates, changes or deletes an
enrolment or a consent; the API owns both. A push for a programme the caller
has no enrolment in is refused (`AreaGone`), and so is a push for a programme
they have left or whose core consent is not live (`ConsentRequired`). On
PostgreSQL the row-level security policies enforce the same rules a second
time, as the final word.

# The conflict policy

**Per-area optimistic concurrency on a monotonic `revision`, with conflicts
returned to the client and never merged by the server.**

A push sends, for each area, the `base_revision` it last saw. If the server's
current revision for that area differs, the push for *that area* is refused and
the server's current bundle is returned alongside it; the areas that did match
are still applied. The client decides what happens next. Last-writer-wins would
let a phone that has been offline for a week silently overwrite a week of
another device's record, and a server-side merge cannot ask the person what
they meant.

`base_revision: null` means "I believe the server has never held this area". If
the server does hold it, that is a conflict too, rather than a create that
overwrites. A non-null `base_revision` for an area the server no longer holds
means the programme was deleted: `AreaGone`, and the client drops its pending
changes for it.

# Nothing is deleted here

The sync tables have no delete grant. A programme's rows go when its enrolment
is deleted (the foreign keys cascade) or with the account, both through the
API. Within a push:

* an answer screen the push no longer carries is stored as `{}` — cleared, its
  old content replaced and gone;
* lapses are append-only. A push must repeat every stored lapse unchanged at
  its position and may add new ones after them; changing or dropping a stored
  lapse is a `LapseConflict`, and so is a new lapse that collides with one
  stored meanwhile. The client then pulls, renumbers its unpushed lapses after
  the server's last one, drops any whose content the server already holds, and
  pushes again, so no lapse is lost to a conflict.

Other devices learn that a programme is gone from `current_areas`, the full
list of the caller's programmes that every pull carries.

# The cursor

`sync_account.change_seq` is a per-account counter. Each write to any of the
account's areas takes the next value and stamps it on the area row, so one
integer can describe "I have seen everything up to here" across areas that are
versioned independently. A pull returns every area whose `change_seq` exceeds
the cursor. The filtered pull is the subtle case; see [pull_since].
"""

from __future__ import annotations

import uuid
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import insert, select, text, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.engine import Connection, Row
from sqlalchemy.exc import IntegrityError

from thsync.logs import log
from thsync.schema import enrolments, sync_account, sync_answer, sync_area, sync_lapse
from thsync.wire import AreaBundle, Conflict, Lapse, ProgrammeCode, PushBundle, ScreenAnswers

__all__ = [
    "AreaGone",
    "ConsentRequired",
    "LapseConflict",
    "PullResult",
    "PushRefused",
    "PushResult",
    "current_areas",
    "current_cursor",
    "load_bundle",
    "pull_since",
    "push_bundles",
    "utcnow",
]


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


@dataclass(frozen=True, slots=True)
class PullResult:
    cursor: int
    bundles: list[AreaBundle]
    current_areas: list[ProgrammeCode]


@dataclass(frozen=True, slots=True)
class PushResult:
    cursor: int
    applied: list[str]
    conflicts: list[Conflict]


class PushRefused(Exception):
    """A push that must not be applied at all. Nothing it carried is written.

    [positions] are indices into the push's `areas` list — positions, not
    programme codes, so the refusal can be reported without naming a
    programme.
    """

    def __init__(self, positions: Sequence[int]) -> None:
        super().__init__(f"push refused at positions {list(positions)}")
        self.positions = list(positions)


class AreaGone(PushRefused):
    """A bundle names a programme with no enrolment, or an area since deleted."""


class ConsentRequired(PushRefused):
    """A bundle names a programme that was left or has no live core consent."""


class LapseConflict(PushRefused):
    """A bundle changes or drops a stored lapse, or collides with a new one."""


@dataclass(frozen=True, slots=True)
class _Enrolment:
    id: uuid.UUID
    status: str


@dataclass(frozen=True, slots=True)
class _Area:
    revision: int


# --- Account bookkeeping -----------------------------------------------------


def current_cursor(connection: Connection, user_id: uuid.UUID) -> int:
    """The account's change counter, or 0 if it has never written."""
    value = connection.execute(
        select(sync_account.c.change_seq).where(sync_account.c.user_id == user_id)
    ).scalar_one_or_none()
    return int(value) if value is not None else 0


def _ensure_account(connection: Connection, user_id: uuid.UUID) -> None:
    """Creates the account row if it is absent; idempotent under concurrency.

    Only `user_id` is written: the counter and timestamps are database
    defaults, and the sync role holds an insert grant on `user_id` alone.
    """
    exists = connection.execute(
        select(sync_account.c.user_id).where(sync_account.c.user_id == user_id)
    ).scalar_one_or_none()
    if exists is not None:
        return
    if connection.dialect.name == "postgresql":
        # Two first pushes racing: the second waits on the key, then does
        # nothing.
        connection.execute(
            pg_insert(sync_account)
            .values(user_id=user_id)
            .on_conflict_do_nothing(index_elements=[sync_account.c.user_id])
        )
    else:
        connection.execute(insert(sync_account).values(user_id=user_id))


def _lock_account(connection: Connection, user_id: uuid.UUID) -> None:
    """Serialises pushes for one account.

    Taken before the areas are read, so a concurrent push for the same account
    waits here and then reads what the first one committed. Without it two
    pushes could both see revision N, and the second would overwrite the
    first's write instead of reporting a conflict.
    """
    connection.execute(
        select(sync_account.c.change_seq)
        .where(sync_account.c.user_id == user_id)
        .with_for_update()
    ).scalar_one()


def _next_seq(connection: Connection, user_id: uuid.UUID) -> int:
    """Claims the next change number for [user_id].

    The increment happens in the database, so it is the row lock rather than
    this process that decides who gets which number. Written as an update and
    then a read rather than one `RETURNING`, so that it behaves identically on
    SQLite builds without it.
    """
    connection.execute(
        update(sync_account)
        .where(sync_account.c.user_id == user_id)
        .values(change_seq=sync_account.c.change_seq + 1)
    )
    return current_cursor(connection, user_id)


# --- Enrolments (read only) --------------------------------------------------


def current_areas(connection: Connection, user_id: uuid.UUID) -> list[ProgrammeCode]:
    """Every programme the caller is enrolled in, including left ones.

    A left programme's data stays, read-only, until the member deletes it, so
    it is still current. A deleted enrolment is absent, and with it its sync
    rows (the foreign keys cascade).
    """
    rows = connection.execute(
        select(enrolments.c.programme_code)
        .where(enrolments.c.user_id == user_id)
        .order_by(enrolments.c.programme_code)
    ).scalars()
    return [code for code in rows]


def _enrolments(
    connection: Connection, user_id: uuid.UUID, codes: Sequence[str]
) -> dict[str, _Enrolment]:
    rows = connection.execute(
        select(enrolments.c.id, enrolments.c.programme_code, enrolments.c.status).where(
            enrolments.c.user_id == user_id, enrolments.c.programme_code.in_(list(codes))
        )
    ).all()
    return {str(row.programme_code): _Enrolment(id=row.id, status=str(row.status)) for row in rows}


def _may_write(connection: Connection, enrolment: _Enrolment) -> bool:
    """Whether the caller may write sync data for [enrolment].

    On PostgreSQL this asks `public.has_consent(enrolment, 'core')`, the same
    function the write policies use: the enrolment is the caller's, not left,
    its core consent is live and account deletion has not started. SQLite has
    no consent tables, so there only the left check applies; the PostgreSQL
    suite (`tests/postgres`) covers the rest.
    """
    if enrolment.status == "left":
        return False
    if connection.dialect.name != "postgresql":
        return True
    allowed = connection.execute(
        text("select public.has_consent(:enrolment_id, 'core')"),
        {"enrolment_id": enrolment.id},
    ).scalar_one()
    return bool(allowed)


# --- Reading -----------------------------------------------------------------


def _areas(
    connection: Connection, user_id: uuid.UUID, codes: Sequence[str]
) -> dict[str, _Area]:
    rows = connection.execute(
        select(sync_area.c.programme_code, sync_area.c.revision).where(
            sync_area.c.user_id == user_id, sync_area.c.programme_code.in_(list(codes))
        )
    ).all()
    return {str(row.programme_code): _Area(revision=int(row.revision)) for row in rows}


def load_bundle(connection: Connection, user_id: uuid.UUID, code: str) -> AreaBundle | None:
    """One programme's bundle, or None if the account has no such area."""
    row = connection.execute(
        select(sync_area.c.programme_code, sync_area.c.revision).where(
            sync_area.c.user_id == user_id, sync_area.c.programme_code == code
        )
    ).one_or_none()
    if row is None:
        return None
    return _bundle_from(connection, user_id, row)


def pull_since(
    connection: Connection,
    user_id: uuid.UUID,
    cursor: int,
    areas: Sequence[str] | None,
) -> PullResult:
    """Bundles changed after [cursor], the cursor to ask from next time, and
    the caller's current programmes.

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

    `current_areas` is never filtered: it is how a device learns that a
    programme was deleted, and a filter must not hide that.
    """
    changed = connection.execute(
        select(sync_area.c.programme_code, sync_area.c.change_seq).where(
            sync_area.c.user_id == user_id, sync_area.c.change_seq > cursor
        )
    ).all()

    wanted = set(areas) if areas is not None else None
    withheld = [
        int(row.change_seq)
        for row in changed
        if wanted is not None and row.programme_code not in wanted
    ]
    selected = [
        str(row.programme_code) for row in changed if wanted is None or row.programme_code in wanted
    ]

    next_cursor = min(withheld) - 1 if withheld else current_cursor(connection, user_id)

    bundles: list[AreaBundle] = []
    for code in sorted(selected):
        bundle = load_bundle(connection, user_id, code)
        if bundle is not None:
            bundles.append(bundle)

    present = current_areas(connection, user_id)
    log.info(
        "pull account=%s from=%d to=%d areas=%d current=%d filtered=%s",
        user_id,
        cursor,
        next_cursor,
        len(bundles),
        len(present),
        wanted is not None,
    )
    return PullResult(cursor=next_cursor, bundles=bundles, current_areas=present)


def _bundle_from(connection: Connection, user_id: uuid.UUID, row: Row[Any]) -> AreaBundle:
    code = str(row.programme_code)
    answer_rows = connection.execute(
        select(sync_answer.c.screen_id, sync_answer.c.payload).where(
            sync_answer.c.user_id == user_id, sync_answer.c.programme_code == code
        )
    ).all()

    return AreaBundle.model_validate(
        {
            "area": code,
            "revision": int(row.revision),
            # Re-attached to the full `programme/screenId` form the client
            # files them under. The prefix is this row's programme, so a stored
            # answer can only ever come back attributed to the programme it is
            # stored in.
            "answers": {
                f"{code}/{answer.screen_id}": ScreenAnswers.model_validate(answer.payload)
                for answer in answer_rows
            },
            "lapses": _stored_lapses(connection, user_id, code),
        }
    )


def _stored_lapses(connection: Connection, user_id: uuid.UUID, code: str) -> list[Lapse]:
    rows = connection.execute(
        select(sync_lapse.c.at, sync_lapse.c.severity, sync_lapse.c.context)
        .where(sync_lapse.c.user_id == user_id, sync_lapse.c.programme_code == code)
        .order_by(sync_lapse.c.ordinal)
    ).all()
    return [
        Lapse(at=_as_utc(row.at), severity=row.severity, context=list(row.context or []))
        for row in rows
    ]


def _as_utc(value: datetime) -> datetime:
    """Reads a stored instant as UTC.

    Postgres hands back an aware datetime from `timestamptz`; SQLite hands back
    a naive one, because it has no timestamp type at all and the driver is
    parsing a string. Everything written here was converted to UTC first, so
    attaching UTC to a naive value restores it — and doing it in one place
    means no caller has to know which database it is talking to.
    """
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


# --- Writing -----------------------------------------------------------------


def push_bundles(
    connection: Connection, user_id: uuid.UUID, bundles: Sequence[PushBundle]
) -> PushResult:
    """Applies each bundle whose `base_revision` matches, reporting the rest.

    Per-area, not all-or-nothing, for revision conflicts: a conflict on one
    programme must not block a write to another, or the segregation is only
    skin deep. A refusal ([PushRefused]) is different — it means the client
    holds something the server must not accept — and refuses the whole push;
    the caller's transaction rolls back.
    """
    codes = [bundle.area for bundle in bundles]

    # Read-only checks first, so that a refused push writes nothing at all.
    enrolled = _enrolments(connection, user_id, codes)
    _refuse_if(
        AreaGone,
        user_id,
        [position for position, bundle in enumerate(bundles) if bundle.area not in enrolled],
    )
    _refuse_if(
        ConsentRequired,
        user_id,
        [
            position
            for position, bundle in enumerate(bundles)
            if not _may_write(connection, enrolled[bundle.area])
        ],
    )

    _ensure_account(connection, user_id)
    _lock_account(connection, user_id)
    existing = _areas(connection, user_id, codes)

    # A revision for an area the server no longer holds: the programme was
    # deleted (its enrolment and, by cascade, its area) since the client last
    # synced. Treating it as a create would file old changes under whatever
    # enrolment exists now.
    _refuse_if(
        AreaGone,
        user_id,
        [
            position
            for position, bundle in enumerate(bundles)
            if bundle.area not in existing and bundle.base_revision is not None
        ],
    )

    applied: list[str] = []
    conflicts: list[Conflict] = []

    for position, bundle in enumerate(bundles):
        area = existing.get(bundle.area)
        if area is not None and area.revision != bundle.base_revision:
            server = load_bundle(connection, user_id, bundle.area)
            assert server is not None  # The area row exists and the account is locked.
            conflicts.append(
                Conflict(
                    area=bundle.area,
                    reason="stale-revision",
                    base_revision=bundle.base_revision,
                    server_revision=area.revision,
                    server=server,
                )
            )
            continue

        seq = _next_seq(connection, user_id)
        _write_area(connection, user_id, bundle, enrolled[bundle.area], area, seq)
        _write_answers(connection, user_id, bundle)
        _append_lapses(connection, user_id, bundle, position)
        applied.append(bundle.area)

    cursor = current_cursor(connection, user_id)
    log.info(
        "push account=%s applied=%d conflicts=%d cursor=%d",
        user_id,
        len(applied),
        len(conflicts),
        cursor,
    )
    return PushResult(cursor=cursor, applied=applied, conflicts=conflicts)


def _refuse_if(kind: type[PushRefused], user_id: uuid.UUID, positions: list[int]) -> None:
    if positions:
        log.info("push refused account=%s reason=%s areas=%d", user_id, kind.__name__, len(positions))
        raise kind(positions)


def _write_area(
    connection: Connection,
    user_id: uuid.UUID,
    bundle: PushBundle,
    enrolment: _Enrolment,
    area: _Area | None,
    seq: int,
) -> None:
    """Creates the area row, or moves it to the next revision.

    The update is conditional on the revision the push was checked against, so
    it can never overwrite a revision it did not see — the account lock makes
    a mismatch impossible, and this makes it impossible to miss if that ever
    changes.
    """
    revision = (bundle.base_revision or 0) + 1
    if area is None:
        connection.execute(
            insert(sync_area).values(
                user_id=user_id,
                enrolment_id=enrolment.id,
                programme_code=bundle.area,
                revision=revision,
                change_seq=seq,
            )
        )
        return
    moved = connection.execute(
        update(sync_area)
        .where(
            sync_area.c.user_id == user_id,
            sync_area.c.programme_code == bundle.area,
            sync_area.c.revision == bundle.base_revision,
        )
        .values(revision=revision, change_seq=seq)
    )
    if moved.rowcount != 1:
        raise RuntimeError("an area's revision changed while its account was locked")


def _write_answers(connection: Connection, user_id: uuid.UUID, bundle: PushBundle) -> None:
    """Makes the stored answers equal the bundle's, without deleting a row.

    New screens are inserted and changed ones replaced. A stored screen the
    bundle no longer carries is replaced by `{}`: the person cleared it, and
    replacing the payload is what makes the old content really gone. Empty
    answer maps are not stored, so a cleared screen is exactly `{}`.
    """
    pushed = {
        screen: answers.model_dump(by_alias=True, exclude_defaults=True)
        for screen, answers in bundle.screen_answers().items()
    }
    stored = {
        str(row.screen_id): row.payload
        for row in connection.execute(
            select(sync_answer.c.screen_id, sync_answer.c.payload).where(
                sync_answer.c.user_id == user_id, sync_answer.c.programme_code == bundle.area
            )
        ).all()
    }

    new = [
        {"user_id": user_id, "programme_code": bundle.area, "screen_id": screen, "payload": payload}
        for screen, payload in pushed.items()
        if screen not in stored
    ]
    if new:
        connection.execute(insert(sync_answer), new)

    replaced = {screen: payload for screen, payload in pushed.items() if screen in stored}
    replaced.update({screen: {} for screen in stored if screen not in pushed})
    for screen, payload in replaced.items():
        if stored[screen] == payload:
            continue
        connection.execute(
            update(sync_answer)
            .where(
                sync_answer.c.user_id == user_id,
                sync_answer.c.programme_code == bundle.area,
                sync_answer.c.screen_id == screen,
            )
            .values(payload=payload)
        )


def _append_lapses(
    connection: Connection, user_id: uuid.UUID, bundle: PushBundle, position: int
) -> None:
    """Inserts the bundle's new lapses after the stored ones.

    Refuses ([LapseConflict]) a bundle that changes or drops a stored lapse, and
    a new lapse whose ordinal is already taken (`23505`).
    """
    stored = _stored_lapses(connection, user_id, bundle.area)
    if len(bundle.lapses) < len(stored) or not all(
        kept.same_as(sent) for kept, sent in zip(stored, bundle.lapses)
    ):
        _refuse_if(LapseConflict, user_id, [position])

    new = [
        {
            "user_id": user_id,
            "programme_code": bundle.area,
            "ordinal": ordinal,
            "at": lapse.at.astimezone(timezone.utc),
            "severity": lapse.severity,
            "context": list(lapse.context),
        }
        for ordinal, lapse in enumerate(bundle.lapses)
        if ordinal >= len(stored)
    ]
    if not new:
        return
    try:
        connection.execute(insert(sync_lapse), new)
    except IntegrityError:
        # The statement and its parameters stay out of the log: they are
        # lapse content.
        log.info("push refused account=%s reason=%s areas=1", user_id, LapseConflict.__name__)
        raise LapseConflict([position]) from None
