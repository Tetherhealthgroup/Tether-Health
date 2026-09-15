"""Fixtures.

Every test gets its own in-memory SQLite database and its own app. Sharing one
would make the cross-account isolation tests meaningless the moment they ran in
a different order.
"""

from __future__ import annotations

import time
from collections.abc import Iterator
from typing import Any

import jwt
import pglast
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, event
from sqlalchemy.dialects import postgresql

from thsync.config import Settings
from thsync.db import create_engine_from_settings, create_schema
from thsync.app import create_app

# At least 32 bytes: PyJWT warns below that for HS256, and a test suite whose
# own fixtures are warned about trains people to ignore the warning.
JWT_SECRET = "test-secret-not-a-real-one-0123456789abcdef"
AUDIENCE = "authenticated"
ISSUER = "https://project.supabase.co/auth/v1"

ALICE = "11111111-1111-1111-1111-111111111111"
BOB = "22222222-2222-2222-2222-222222222222"


@pytest.fixture
def settings() -> Settings:
    return Settings(
        database_url="sqlite+pysqlite:///:memory:",
        jwt_secret=JWT_SECRET,
        jwt_audience=AUDIENCE,
        jwt_issuer=ISSUER,
        jwt_leeway_seconds=0,
        sql_echo=False,
    )


#: PostgreSQL, in the paramstyle whose placeholders are themselves valid SQL.
#:
#: SQLAlchemy's default `pyformat` renders `%(id)s`, which is psycopg's
#: client-side interpolation and not something PostgreSQL's grammar accepts;
#: `numeric` renders `:1`, which it also does not. `numeric_dollar` renders
#: `$1`, a real PostgreSQL parameter, so the compiled statement can be handed
#: to the server's own parser unchanged.
_POSTGRES = postgresql.dialect(paramstyle="numeric_dollar")  # type: ignore[no-untyped-call]


@pytest.fixture
def engine(settings: Settings) -> Iterator[Engine]:
    built = create_engine_from_settings(settings)

    # Every statement this suite runs, checked against PostgreSQL's grammar.
    #
    # The tests execute on SQLite because no PostgreSQL can run in the
    # environment this was written in — the sandbox denies `shmget`, so even
    # `initdb` cannot bootstrap a cluster. That leaves a specific hole: SQLite
    # is famously lenient, so a query it accepts may still be rejected by the
    # server in production, and the suite would be green either way.
    #
    # This closes most of that hole without a server. Each statement is
    # compiled a second time for the PostgreSQL dialect and parsed by
    # `libpg_query`, which is the server's own `gram.y` built as a library. A
    # construct Postgres cannot parse now fails here, in the test that used it,
    # rather than on the first deploy.
    #
    # It proves syntax and dialect support, not behaviour: a statement can
    # parse and still return different results, and the two places that is most
    # likely — `timestamptz` offsets and `jsonb` — are called out in the README
    # as needing a live server.
    @event.listens_for(built, "before_execute")
    def _must_be_valid_postgresql(
        conn: Any,
        clauseelement: Any,
        multiparams: Any,
        params: Any,
        execution_options: Any,
    ) -> None:
        compiled = clauseelement.compile(dialect=_POSTGRES)
        try:
            pglast.parse_sql(str(compiled))
        except pglast.parser.ParseError as error:  # pragma: no cover - a failure
            raise AssertionError(
                f"statement is not valid PostgreSQL: {error}\n\n{compiled}"
            ) from error

    create_schema(built)
    yield built
    built.dispose()


@pytest.fixture
def client(settings: Settings, engine: Engine) -> Iterator[TestClient]:
    # `raise_server_exceptions=False` so that the 500 handler in
    # thsync.problems is exercised by a test rather than bypassed by the test
    # client re-raising the original exception.
    with TestClient(
        create_app(settings=settings, engine=engine), raise_server_exceptions=False
    ) as test_client:
        yield test_client


def token(
    subject: str = ALICE,
    *,
    secret: str = JWT_SECRET,
    audience: str = AUDIENCE,
    issuer: str | None = ISSUER,
    expires_in: int = 3600,
    algorithm: str = "HS256",
    **overrides: Any,
) -> str:
    """A Supabase-shaped access token, with every part overridable.

    The defaults are the valid case; each auth test changes exactly one thing,
    so a test that fails names the claim that broke it.
    """
    now = int(time.time())
    claims: dict[str, Any] = {
        "sub": subject,
        "aud": audience,
        "iat": now,
        "exp": now + expires_in,
        "role": "authenticated",
    }
    if issuer is not None:
        claims["iss"] = issuer
    claims.update(overrides)
    return jwt.encode(claims, secret, algorithm=algorithm)


def auth(subject: str = ALICE, **kwargs: Any) -> dict[str, str]:
    return {"Authorization": f"Bearer {token(subject, **kwargs)}"}


def bundle(
    area: str = "tobacco",
    *,
    base_revision: int | None = None,
    status: str = "active",
    answers: dict[str, dict[str, Any]] | None = None,
    lapses: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """One push bundle, shaped exactly as `TetherSession.toJson()` writes it."""
    return {
        "area": area,
        "base_revision": base_revision,
        "enrolment": {
            "status": status,
            "hidden": False,
            "joinedOn": "2026-09-15T07:00:00.000Z",
            "sharing": {"totalsAndAdherence": True, "notes": False, "recipient": None},
        },
        "answers": answers
        if answers is not None
        else {
            f"{area}/S05": {
                "chips": {"0": [1, 2]},
                "option": {"1": 3},
                "slider": {"2": 90.0},
                "text": {"3": "free text"},
            }
        },
        "lapses": lapses
        if lapses is not None
        else [
            {
                "at": "2026-09-15T07:00:00.000Z",
                "severity": "minor",
                "context": ["stress"],
            }
        ],
    }
