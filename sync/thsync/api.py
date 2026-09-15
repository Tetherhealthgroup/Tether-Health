"""The `/v1` endpoints.

Every handler here is a plain `def`. Starlette runs those on a worker thread,
which is what lets the synchronous SQLAlchemy engine be used without an async
driver — see `thsync.db` for why that trade was taken.

Every handler takes `account` from [require_account] and passes `account.id`
into every repository call. There is no other way to name an account in this
API, and `thsync.repository` takes `account_id` as a required first argument on
every read and every write, so a query that forgot to scope itself would not
compile as a call.
"""

from __future__ import annotations

from collections.abc import Iterator
from typing import Annotated

from fastapi import APIRouter, Depends, Path, Request, Response, status
from sqlalchemy import Engine
from sqlalchemy.engine import Connection

from thsync import repository
from thsync.auth import Account, account_from_request
from thsync.config import Settings
from thsync.db import transaction
from thsync.problems import Problem
from thsync.wire import (
    AREA_ID_PATTERN,
    PullRequest,
    PullResponse,
    PushRequest,
    PushResponse,
    RevokeResponse,
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


def db(request: Request) -> Iterator[Connection]:
    """One transaction per request, committed when the handler returns.

    A generator dependency rather than a `with` block inside each handler, so
    that a handler cannot return a 200 describing work that a later exception
    rolled back: FastAPI closes this after the response is produced, and an
    exception escaping the handler propagates through the generator and aborts
    the transaction.
    """
    with transaction(_engine(request)) as connection:
        yield connection


AccountDep = Annotated[Account, Depends(require_account)]
ConnectionDep = Annotated[Connection, Depends(db)]


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
    """Area bundles changed since `cursor`.

    A `cursor` above the account's own counter is refused rather than clamped.
    It means the client is holding a cursor this database never issued — a
    restore from backup, or a token that now names a different account — and
    continuing from it would skip every change below the phantom number.
    """
    cursor = body.cursor or 0
    server_cursor = repository.current_cursor(connection, account.id)
    if cursor > server_cursor:
        raise _stale_cursor(cursor, server_cursor)

    result = repository.pull_since(connection, account.id, cursor, body.areas)
    return PullResponse(
        cursor=result.cursor, areas=result.bundles, server_time=repository.utcnow()
    )


@router.post("/sync/push", response_model=PushResponse, tags=["sync"])
def push(body: PushRequest, account: AccountDep, connection: ConnectionDep) -> PushResponse:
    """Applies the bundles whose revisions match; reports the rest as conflicts.

    Answers with 200 even when every bundle conflicted. A conflict is not a
    failed request — the server did exactly what it was asked and is reporting
    the outcome per area — and a 409 would give the client no way to express
    "two of these five applied", which is the normal case.
    """
    server_cursor = repository.current_cursor(connection, account.id)
    if body.base_cursor is not None and body.base_cursor > server_cursor:
        raise _stale_cursor(body.base_cursor, server_cursor)

    result = repository.push_bundles(connection, account.id, body.areas)
    return PushResponse(
        cursor=result.cursor,
        applied=result.applied,
        conflicts=result.conflicts,
        server_time=repository.utcnow(),
    )


@router.delete("/sync/areas/{area_id}", response_model=RevokeResponse, tags=["sync"])
def revoke(
    account: AccountDep,
    connection: ConnectionDep,
    area_id: Annotated[str, Path(pattern=AREA_ID_PATTERN.pattern, max_length=64)],
) -> RevokeResponse:
    """Revokes consent for one programme and destroys its data.

    The other programmes are not read, not rewritten and not re-versioned. That
    is the 42 CFR Part 2 requirement this endpoint exists to satisfy, and it is
    covered by `tests/test_segregation.py`.
    """
    result = repository.revoke_area(connection, account.id, area_id)
    if result is None:
        raise Problem(
            status_code=status.HTTP_404_NOT_FOUND,
            code="unknown-area",
            title="Not found",
            detail="This account has no record for that programme.",
        )
    return RevokeResponse(
        area=area_id,
        revision=result.revision,
        cursor=result.cursor,
        server_time=repository.utcnow(),
    )


@router.delete("/sync/account", status_code=status.HTTP_204_NO_CONTENT, tags=["sync"])
def erase(account: AccountDep, connection: ConnectionDep) -> Response:
    """Destroys everything held for the account.

    204 with no body, including when there was nothing to destroy. The client
    calls this from `sessionErased`, where the person has already been told
    their record is gone; a 404 on the retry after a dropped connection would
    contradict that for no reason.
    """
    repository.erase_account(connection, account.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


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
