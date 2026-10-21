"""The `/v1` endpoints.

Every handler here is a plain `def`. Starlette runs those on a worker thread,
which is what lets the synchronous SQLAlchemy engine be used without an async
driver — see `thsync.db` for why that trade was taken.

Every handler takes `account` from [require_account] and passes `account.id`
into every repository call. There is no other way to name an account in this
API, and `thsync.repository` takes `user_id` as a required argument on every
read and every write, so a query that forgot to scope itself would not compile
as a call. On PostgreSQL the transaction also acts as that user
(`thsync.db.transaction`), so row-level security scopes every statement a
second time.

There is no delete route. A programme's sync data is deleted with its
enrolment, and an account's with the account, both through the API.
"""

from __future__ import annotations

from collections.abc import Iterator
from typing import Annotated

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy import Engine
from sqlalchemy.engine import Connection

from thsync import repository
from thsync.auth import Account, account_from_request
from thsync.config import Settings
from thsync.db import transaction
from thsync.problems import Problem
from thsync.wire import (
    PullRequest,
    PullResponse,
    PushRequest,
    PushResponse,
)

__all__ = ["router", "require_account"]

router = APIRouter(prefix="/v1")


def _settings(request: Request) -> Settings:
    return request.app.state.settings  # type: ignore[no-any-return]


def _engine(request: Request) -> Engine:
    return request.app.state.engine  # type: ignore[no-any-return]


def require_account(request: Request) -> Account:
    """The authenticated caller, or a 401 problem."""
    return account_from_request(request, _settings(request))


AccountDep = Annotated[Account, Depends(require_account)]


def db(request: Request, account: AccountDep) -> Iterator[Connection]:
    """One transaction per request, acting as the caller, committed when the
    handler returns.

    A generator dependency rather than a `with` block inside each handler: an
    exception escaping the handler propagates through the generator and aborts
    the transaction. Function scope makes the commit happen before the
    response is sent, so a commit that fails is a 500, never a 200 describing
    work that was rolled back.
    """
    with transaction(_engine(request), account.id) as connection:
        yield connection


ConnectionDep = Annotated[Connection, Depends(db, scope="function")]


@router.get("/health", summary="Liveness probe", tags=["ops"])
def health() -> dict[str, str]:
    """Unauthenticated and does not touch the database.

    A health check that ran a query would turn every database blip into a
    removed instance, and a health check behind auth cannot be used by the
    thing that needs it. Readiness — can this instance reach Postgres — is a
    different question and deliberately not answered here.
    """
    return {"status": "ok"}


@router.post("/sync/pull", response_model=PullResponse, tags=["sync"])
def pull(body: PullRequest, account: AccountDep, connection: ConnectionDep) -> PullResponse:
    """Area bundles changed since `cursor`, and the caller's current programmes.

    A `cursor` above the account's own counter is refused rather than clamped.
    It means the client is holding a cursor this database never issued — a
    restore from backup, or a token that now names a different account — and
    continuing from it would skip every change below the phantom number.

    `current_areas` lists every programme the caller has, whatever the filter.
    A client drops any local area missing from it, with its unpushed changes.
    """
    cursor = body.cursor or 0
    server_cursor = repository.current_cursor(connection, account.id)
    if cursor > server_cursor:
        raise _stale_cursor(cursor, server_cursor)

    result = repository.pull_since(connection, account.id, cursor, body.areas)
    return PullResponse(
        cursor=result.cursor,
        areas=result.bundles,
        current_areas=result.current_areas,
        server_time=repository.utcnow(),
    )


@router.post("/sync/push", response_model=PushResponse, tags=["sync"])
def push(body: PushRequest, account: AccountDep, connection: ConnectionDep) -> PushResponse:
    """Applies the bundles whose revisions match; reports the rest as conflicts.

    Answers with 200 even when every bundle conflicted. A conflict is not a
    failed request — the server did exactly what it was asked and is reporting
    the outcome per area — and a 409 would give the client no way to express
    "two of these five applied", which is the normal case.

    Refused as a whole, with nothing written:

    * `409 area_gone` — a bundle names a programme the caller has no enrolment
      in, or claims a revision for an area that has since been deleted. The
      client discards that area's pending changes.
    * `403 consent_required` — a bundle names a programme the caller has left,
      or whose core consent is not live, or account deletion has started.
    * `409 lapse_conflict` — a bundle changes or drops a stored lapse, or a new
      lapse collides with one stored meanwhile. The client pulls, renumbers its
      unpushed lapses after the server's last one, drops any the server already
      holds, and pushes again.

    Each names the bundles by position in `areas`, never by programme.
    """
    server_cursor = repository.current_cursor(connection, account.id)
    if body.base_cursor is not None and body.base_cursor > server_cursor:
        raise _stale_cursor(body.base_cursor, server_cursor)

    try:
        result = repository.push_bundles(connection, account.id, body.areas)
    except repository.AreaGone as refused:
        raise Problem(
            status_code=status.HTTP_409_CONFLICT,
            code="area_gone",
            title="Conflict",
            detail=(
                "A programme in this push has no enrolment, or was deleted. "
                "Discard its pending changes; nothing was saved."
            ),
            positions=refused.positions,
        ) from None
    except repository.ConsentRequired as refused:
        raise Problem(
            status_code=status.HTTP_403_FORBIDDEN,
            code="consent_required",
            title="Forbidden",
            detail=(
                "A programme in this push has no live consent for its data to be "
                "saved. Nothing was saved."
            ),
            positions=refused.positions,
        ) from None
    except repository.LapseConflict as refused:
        raise Problem(
            status_code=status.HTTP_409_CONFLICT,
            code="lapse_conflict",
            title="Conflict",
            detail=(
                "Stored lapses cannot be changed or removed, and a new lapse "
                "collided with one already stored. Pull, place unsent lapses "
                "after the stored ones, and push again; nothing was saved."
            ),
            positions=refused.positions,
        ) from None
    return PushResponse(
        cursor=result.cursor,
        applied=result.applied,
        conflicts=result.conflicts,
        server_time=repository.utcnow(),
    )


def _stale_cursor(given: int, server: int) -> Problem:
    return Problem(
        status_code=status.HTTP_409_CONFLICT,
        code="unknown-cursor",
        title="Conflict",
        detail=(
            "The cursor is ahead of this account's history. Pull from cursor "
            "null to resynchronise."
        ),
        cursor=server,
        given_cursor=given,
    )
