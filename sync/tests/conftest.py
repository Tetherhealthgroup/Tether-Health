"""Fixtures.

Every test gets its own in-memory SQLite database and its own app. Sharing one
would make the cross-account isolation tests meaningless the moment they ran in
a different order.
"""

from __future__ import annotations

import time
import uuid
from collections.abc import Callable, Iterator
from typing import Any

import jwt
import pglast
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, event, insert, update
from sqlalchemy.dialects import postgresql

from thsync.app import create_app
from thsync.config import Settings
from thsync.db import create_engine_from_settings, create_schema
from thsync.schema import enrolments

# At least 32 bytes: PyJWT warns below that for HS256, and a test suite whose
# own fixtures are warned about trains people to ignore the warning.
JWT_SECRET = "test-secret-not-a-real-one-0123456789abcdef"
AUDIENCE = "authenticated"
ISSUER = "https://project.supabase.co/auth/v1"

# Synthetic user ids.
ALICE = "11111111-1111-4111-8111-111111111111"
BOB = "22222222-2222-4222-8222-222222222222"


@pytest.fixture
def settings() -> Settings:
    return Settings(
        database_url="sqlite+pysqlite:///:memory:",
        jwt_secret=JWT_SECRET,
        jwt_jwks_url=None,
        jwt_audience=AUDIENCE,
        jwt_issuer=ISSUER,
        jwt_leeway_seconds=0,
        sql_echo=False,
        environment="development",
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
    # Most tests execute on SQLite, so they run anywhere without a server.
    # That leaves a specific hole: SQLite is famously lenient, so a query it
    # accepts may still be rejected by the server in production. The
    # PostgreSQL suite (`test_postgres.py`) runs the service against a real
    # server where one is configured; this check runs everywhere.
    #
    # This closes most of that hole without a server. Each statement is
    # compiled a second time for the PostgreSQL dialect and parsed by
    # `libpg_query`, which is the server's own `gram.y` built as a library. A
    # construct Postgres cannot parse now fails here, in the test that used it,
    # rather than on the first deploy.
    #
    # It proves syntax and dialect support, not behaviour: a statement can
    # parse and still return different results.
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


def enrol_in(engine: Engine) -> Callable[..., uuid.UUID]:
    """Returns a helper that enrols a user in a programme, as the API would.

    The sync service only reads `enrolments`; on SQLite the tests write the
    rows the API would have written.
    """

    def enrol(user: str = ALICE, *codes: str, status: str = "focus") -> uuid.UUID:
        enrolment_id = uuid.uuid4()
        with engine.begin() as connection:
            for code in codes or ("bf",):
                enrolment_id = uuid.uuid4()
                connection.execute(
                    insert(enrolments).values(
                        id=enrolment_id,
                        user_id=uuid.UUID(user),
                        programme_code=code,
                        status=status,
                    )
                )
        return enrolment_id

    return enrol


@pytest.fixture
def enrol(engine: Engine) -> Callable[..., uuid.UUID]:
    return enrol_in(engine)


def set_status(engine: Engine, user: str, code: str, status: str) -> None:
    with engine.begin() as connection:
        connection.execute(
            update(enrolments)
            .where(enrolments.c.user_id == uuid.UUID(user), enrolments.c.programme_code == code)
            .values(status=status)
        )


def bundle(
    area: str = "bf",
    *,
    base_revision: int | None = None,
    answers: dict[str, dict[str, Any]] | None = None,
    lapses: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """One push bundle: one programme's answers and lapses."""
    return {
        "area": area,
        "base_revision": base_revision,
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
