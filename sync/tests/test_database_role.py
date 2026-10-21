"""The database login, and the identity each transaction takes.

The service refuses to start on a privileged or wrong database login.

On PostgreSQL the service must log in as `thsync`: not a superuser, not a role
that bypasses row-level security, holding no privileged role, with no role set
at session level, and a member of `authenticated` only. Anything else stops the
process at start-up, before the first request.

Each transaction on PostgreSQL first runs `SET LOCAL ROLE authenticated` and
sets `request.jwt.claims` to the verified subject, transaction-locally.

These tests check the decisions and their wiring without a server.
`test_postgres.py` checks the same against a real server, where the facts come
from the catalogue.
"""

from __future__ import annotations

import json
import uuid
from dataclasses import replace
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from thsync import db
from thsync.app import create_app
from thsync.config import Settings
from thsync.db import RoleFacts, StartupRefused, role_refusal

SYNC_LOGIN = RoleFacts(
    session_user="thsync",
    current_user="thsync",
    superuser=False,
    bypass_rls=False,
    create_role=False,
    replication=False,
    member_of=("authenticated",),
    privileged=(),
)


def test_the_sync_login_may_start() -> None:
    assert role_refusal(SYNC_LOGIN) is None


@pytest.mark.parametrize(
    ("facts", "reason"),
    [
        (replace(SYNC_LOGIN, session_user="postgres", current_user="postgres", superuser=True),
         "superuser"),
        (replace(SYNC_LOGIN, superuser=True), "superuser"),
        (replace(SYNC_LOGIN, bypass_rls=True), "bypasses row-level security"),
        (replace(SYNC_LOGIN, create_role=True), "can create roles"),
        (replace(SYNC_LOGIN, replication=True), "can replicate"),
        (replace(SYNC_LOGIN, session_user="service_role", current_user="service_role"),
         "must be the role thsync"),
        (replace(SYNC_LOGIN, session_user="authenticator", current_user="authenticator"),
         "must be the role thsync"),
        (replace(SYNC_LOGIN, session_user="authenticated", current_user="authenticated"),
         "must be the role thsync"),
        (replace(SYNC_LOGIN, privileged=("service_role",)), "privileged role: service_role"),
        (replace(SYNC_LOGIN, privileged=("pg_write_all_data",)), "privileged role"),
        (replace(SYNC_LOGIN, current_user="authenticated"), "role set at session level"),
        (replace(SYNC_LOGIN, member_of=("anon", "authenticated")), "authenticated only"),
        (replace(SYNC_LOGIN, member_of=()), "authenticated only"),
    ],
)
def test_a_privileged_or_wrong_login_is_refused(facts: RoleFacts, reason: str) -> None:
    refusal = role_refusal(facts)
    assert refusal is not None
    assert reason in refusal


def _postgres_app(settings: Settings) -> TestClient:
    # Never connected: the role facts are supplied by the test.
    engine = create_engine("postgresql+psycopg://thsync@127.0.0.1:1/never")
    return TestClient(create_app(settings=settings, engine=engine))


def test_start_up_refuses_a_superuser_login(
    settings: Settings, monkeypatch: pytest.MonkeyPatch
) -> None:
    superuser = replace(SYNC_LOGIN, session_user="postgres", current_user="postgres", superuser=True)
    monkeypatch.setattr(db, "login_role_facts", lambda _engine: superuser)
    with pytest.raises(StartupRefused, match="superuser"):
        with _postgres_app(settings):
            pass  # pragma: no cover - start-up must not get here


def test_start_up_refuses_the_service_role(
    settings: Settings, monkeypatch: pytest.MonkeyPatch
) -> None:
    service = replace(
        SYNC_LOGIN, session_user="service_role", current_user="service_role", bypass_rls=True
    )
    monkeypatch.setattr(db, "login_role_facts", lambda _engine: service)
    with pytest.raises(StartupRefused):
        with _postgres_app(settings):
            pass  # pragma: no cover - start-up must not get here


def test_start_up_proceeds_for_the_sync_login(
    settings: Settings, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(db, "login_role_facts", lambda _engine: SYNC_LOGIN)
    with _postgres_app(settings) as client:
        assert client.get("/v1/health").status_code == 200


class _RecordingConnection:
    """Stands in for a PostgreSQL connection and records what it is asked."""

    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, Any] | None]] = []

    def execute(self, statement: Any, parameters: dict[str, Any] | None = None) -> None:
        self.calls.append((str(statement), parameters))


def test_each_transaction_takes_the_caller_s_identity_locally() -> None:
    user = uuid.UUID("11111111-1111-4111-8111-111111111111")
    connection = _RecordingConnection()
    db._act_as(connection, user)  # type: ignore[arg-type]

    (role, _), (claims_sql, params) = connection.calls
    assert role == "set local role authenticated"
    # Both settings transaction-local (`true`), so a pooled connection never
    # carries one caller into the next transaction.
    assert "set_config('request.jwt.claims', :claims, true)" in claims_sql
    assert "set_config('request.jwt.claim.sub', '', true)" in claims_sql
    # The subject is a bound parameter inside JSON, never SQL text.
    assert str(user) not in claims_sql
    assert params is not None
    assert json.loads(params["claims"]) == {"sub": str(user), "role": "authenticated"}
