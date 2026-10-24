"""Errors as RFC 7807 Problem Details.

Every failure leaves this service as `application/problem+json` with `type`,
`title`, `status` and `detail`, because that is what the rest of the Tether
backend speaks and a client that has to special-case one service's error shape
will get it wrong for that one service.

The rule that shapes the rest of this module: **a problem body carries
positions and codes, never content**. An error body is the response most likely
to be captured verbatim — by an aggregator, a proxy access log, a crash
reporter, a support ticket screenshot — while a 200 body is not. So a 422 here
will tell you that the third bundle's answers failed validation and why the
rule exists; it will not tell you which programme it was or what the person
typed. That is deliberately less convenient than echoing the offending value,
and the trade is: debugging cost for us, against a programme name for somebody
in a log we do not control.
"""

from __future__ import annotations

from typing import Any, Final

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from thsync.logs import log

__all__ = ["Problem", "PROBLEM_TYPE_BASE", "install_problem_handlers", "problem_response"]

#: Base for the `type` URI. Documentation does not have to exist at these URLs
#: for the field to do its job — RFC 7807 §3.1 says `type` is an identifier
#: first — but they are namespaced so that a client can switch on them safely.
#:
#: NOTE: this base was chosen to match the repo's domain. It has NOT been
#: checked against the sibling Node service, which is not present in this
#: repository; if that service uses a different base, change it here.
PROBLEM_TYPE_BASE: Final = "https://tetherhealthgroup.com/problems/"

MEDIA_TYPE: Final = "application/problem+json"


class Problem(Exception):
    """A failure that already knows how it should look on the wire.

    Raised instead of `HTTPException` so that the `type`/`title` pair is chosen
    at the point that knows what went wrong, rather than reconstructed from a
    status code by a handler that does not.
    """

    def __init__(
        self,
        *,
        status_code: int,
        code: str,
        title: str,
        detail: str,
        headers: dict[str, str] | None = None,
        **extensions: Any,
    ) -> None:
        super().__init__(detail)
        self.status_code = status_code
        self.code = code
        self.title = title
        self.detail = detail
        self.headers = headers
        self.extensions = extensions

    def to_response(self) -> JSONResponse:
        return problem_response(
            status_code=self.status_code,
            code=self.code,
            title=self.title,
            detail=self.detail,
            headers=self.headers,
            **self.extensions,
        )


def problem_response(
    *,
    status_code: int,
    code: str,
    title: str,
    detail: str,
    headers: dict[str, str] | None = None,
    **extensions: Any,
) -> JSONResponse:
    """Builds the `application/problem+json` response for one failure."""
    body: dict[str, Any] = {
        "type": f"{PROBLEM_TYPE_BASE}{code}",
        "title": title,
        "status": status_code,
        "detail": detail,
    }
    body.update(extensions)
    return JSONResponse(
        body, status_code=status_code, media_type=MEDIA_TYPE, headers=headers
    )


def install_problem_handlers(app: FastAPI) -> None:
    """Routes every way this app can fail through [problem_response]."""

    @app.exception_handler(Problem)
    async def _problem(_: Request, exc: Problem) -> JSONResponse:  # pyright: ignore[reportUnusedFunction]
        return exc.to_response()

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:  # pyright: ignore[reportUnusedFunction]
        errors = [
            {"at": _safe_location(error.get("loc", ())), "code": str(error.get("type", "invalid"))}
            for error in exc.errors()
        ]
        # Count only. `exc.errors()` carries an `input` key holding the value
        # that failed, which for this API is answer text or a lapse context —
        # the two fields that must never reach a log line.
        log.info("request rejected: %d validation error(s)", len(errors))
        return problem_response(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            code="invalid-request",
            title="Request body is not valid",
            detail=(
                f"{len(errors)} field(s) failed validation. Positions and error "
                "codes are listed; values are withheld because they may carry "
                "clinical content."
            ),
            errors=errors,
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:  # pyright: ignore[reportUnusedFunction]
        # Covers the responses the framework raises on our behalf — 404 for an
        # unrouted path, 405, and the 401s from the security dependency — so
        # that a client never sees a bare `{"detail": …}` from one endpoint and
        # a problem document from the next.
        return problem_response(
            status_code=exc.status_code,
            code=_CODES.get(exc.status_code, "error"),
            title=_TITLES.get(exc.status_code, "Request failed"),
            detail=str(exc.detail),
            headers=dict(exc.headers) if exc.headers else None,
        )

    @app.exception_handler(Exception)
    async def _unhandled(_: Request, exc: Exception) -> JSONResponse:  # pyright: ignore[reportUnusedFunction]
        # The exception type goes to the log; the body says nothing. A stack
        # frame or a driver message in a 500 body is how a database URL, a
        # table name, or a bound parameter ends up on somebody's screen.
        log.exception("unhandled %s", type(exc).__name__)
        return problem_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="internal-error",
            title="Internal server error",
            detail="The request could not be completed. Nothing was changed.",
        )


#: Field names this API defines. Anything in a validation `loc` that is not one
#: of these is a value the caller chose — a programme id, an answer key, a
#: block index — and is replaced by `*` on its way into a problem body. The set
#: is populated by `thsync.wire` at import time so that adding a field to a
#: model cannot silently start redacting it.
KNOWN_FIELD_NAMES: set[str] = {"body", "query", "path", "header", "cookie"}

_MAX_LOCATION_DEPTH: Final = 4

_CODES: Final[dict[int, str]] = {
    400: "invalid-request",
    401: "unauthenticated",
    403: "forbidden",
    404: "not-found",
    405: "method-not-allowed",
    409: "conflict",
    413: "payload-too-large",
    415: "unsupported-media-type",
    422: "invalid-request",
    429: "too-many-requests",
}

_TITLES: Final[dict[int, str]] = {
    400: "Bad request",
    401: "Not authenticated",
    403: "Forbidden",
    404: "Not found",
    405: "Method not allowed",
    409: "Conflict",
    413: "Payload too large",
    415: "Unsupported media type",
    422: "Request body is not valid",
    429: "Too many requests",
}


def _safe_location(loc: object) -> str:
    """Renders a pydantic error location with caller-chosen names removed.

    List indices survive (`areas.2` is a position, not content) and so do the
    names of fields this service declares. Everything else becomes `*`: the
    keys of `answers` are `areaId/screenId`, and a programme id in an error
    body is precisely the disclosure Part 2 is about.
    """
    if not isinstance(loc, (list, tuple)):
        return "*"
    parts: list[str] = []
    for segment in loc[:_MAX_LOCATION_DEPTH]:
        if isinstance(segment, int):
            parts.append(str(segment))
        elif isinstance(segment, str) and segment in KNOWN_FIELD_NAMES:
            parts.append(segment)
        else:
            parts.append("*")
    if isinstance(loc, (list, tuple)) and len(loc) > _MAX_LOCATION_DEPTH:
        parts.append("…")
    return ".".join(parts) or "*"
