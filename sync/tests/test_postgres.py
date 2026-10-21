"""The service against a real PostgreSQL server, with the real migrations.

Runs only when `THSYNC_TEST_DATABASE_URL` names a superuser connection to a
local server (127.0.0.1 or localhost); skipped otherwise, and a failure instead
of a skip when `THSYNC_REQUIRE_POSTGRES=1` (CI sets both). The suite:

1. creates a scratch database and applies `tests/postgres/supabase_stand_in.sql`
   (minimal Supabase roles, `auth` and `storage`) and then every file in
   `supabase/migrations`, in order;
2. gives the `thsync` role a login with a random password generated for this
   run, and drives the app through it, exactly as production would;
3. seeds synthetic users, enrolments and consents as the superuser, the way
   the API would have created them.

What it proves that the SQLite suite cannot: the start-up role check against
the catalogue; that per-transaction `SET LOCAL ROLE` and claims make the
row-level security policies, column grants and `has_consent` apply to every
statement the service runs; and that the cascades, `timestamptz` and `jsonb`
behave as the code expects. It is not the Supabase image and has no
connection pooler.
"""

from __future__ import annotations

import os
import secrets
import uuid
from collections.abc import Callable, Iterator
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import DBAPIError

from thsync import repository
from thsync.app import create_app
from thsync.config import Settings
from thsync.db import StartupRefused, login_role_facts, role_refusal, transaction
from conftest import auth, bundle

pytestmark = pytest.mark.postgres

_URL = os.environ.get("THSYNC_TEST_DATABASE_URL", "")
_SYNC_ROOT = Path(__file__).resolve().parents[1]
_STAND_IN = _SYNC_ROOT / "tests" / "postgres" / "supabase_stand_in.sql"
_MIGRATIONS = _SYNC_ROOT.parent / "supabase" / "migrations"
_CONSENT_VERSION = "sync-test-1"


def _require_server() -> str:
    if not _URL:
        if os.environ.get("THSYNC_REQUIRE_POSTGRES") == "1":
            pytest.fail("THSYNC_REQUIRE_POSTGRES=1 but THSYNC_TEST_DATABASE_URL is not set")
        pytest.skip("THSYNC_TEST_DATABASE_URL is not set; no PostgreSQL server for this run")
    url = make_url(_URL)
    if url.host not in ("127.0.0.1", "localhost"):
        pytest.fail("THSYNC_TEST_DATABASE_URL must name a local server (127.0.0.1 or localhost)")
    return _URL


def _run_script(engine: Engine, sql: str) -> None:
    """Runs a whole SQL file, as psql would: simple protocol, no parameters."""
    raw = engine.raw_connection()
    try:
        cursor = raw.cursor()
        cursor.execute(sql)
        cursor.close()
    finally:
        raw.close()


@pytest.fixture(scope="module")
def database() -> Iterator[dict[str, Engine]]:
    """A migrated scratch database: a superuser engine and a `thsync` engine."""
    base = make_url(_require_server()).set(drivername="postgresql+psycopg")
    name = f"thsync_test_{secrets.token_hex(6)}"
    password = secrets.token_hex(24)

    server = create_engine(base, isolation_level="AUTOCOMMIT")
    with server.connect() as connection:
        connection.execute(text(f'create database "{name}"'))

    admin = create_engine(base.set(database=name), isolation_level="AUTOCOMMIT")
    try:
        _run_script(admin, _STAND_IN.read_text())
        for path in sorted(_MIGRATIONS.glob("*.sql")):
            _run_script(admin, path.read_text())
        # The one step that is human-run in production: giving thsync a login.
        # The password is random per run and exists only in this process.
        _run_script(admin, f"alter role thsync login password '{password}'")
        _run_script(
            admin,
            "insert into public.consent_documents (purpose, version, locale, body, effective_from) "
            f"values ('core', '{_CONSENT_VERSION}', 'en', 'Synthetic core wording', now())",
        )
        sync = create_engine(
            base.set(database=name, username="thsync", password=password),
            hide_parameters=True,
        )
        yield {"admin": admin, "sync": sync}
        sync.dispose()
    finally:
        try:
            _run_script(
                admin,
                "do $$ begin if exists (select 1 from pg_catalog.pg_roles where rolname = 'thsync') "
                "then alter role thsync nologin password null; end if; end $$",
            )
        finally:
            admin.dispose()
        with server.connect() as connection:
            connection.execute(text(f'drop database if exists "{name}" with (force)'))
        server.dispose()


@pytest.fixture
def pg_settings(settings: Settings) -> Settings:
    return Settings(
        database_url="postgresql+psycopg://",
        jwt_secret=settings.jwt_secret,
        jwt_jwks_url=None,
        jwt_audience=settings.jwt_audience,
        jwt_issuer=settings.jwt_issuer,
        jwt_leeway_seconds=0,
        sql_echo=False,
        environment="development",
    )


@pytest.fixture
def pg_client(database: dict[str, Engine], pg_settings: Settings) -> Iterator[TestClient]:
    with TestClient(
        create_app(settings=pg_settings, engine=database["sync"]), raise_server_exceptions=False
    ) as client:
        yield client


class Seed:
    """Synthetic members, enrolments and consents, written as the API would."""

    def __init__(self, admin: Engine) -> None:
        self.admin = admin

    def member(self) -> str:
        user = uuid.uuid4()
        with self.admin.connect() as connection:
            connection.execute(
                text(
                    "insert into auth.users (id, email, aud, role) "
                    "values (:id, :email, 'authenticated', 'authenticated')"
                ),
                {"id": user, "email": f"synthetic-{user.hex[:8]}@example.test"},
            )
        return str(user)

    def enrol(self, user: str, code: str, *, status: str = "learn_only", consent: bool = True) -> uuid.UUID:
        with self.admin.connect() as connection:
            enrolment: uuid.UUID = connection.execute(
                text(
                    "insert into public.enrolments (user_id, programme_code, status) "
                    "values (:user, :code, :status) returning id"
                ),
                {"user": uuid.UUID(user), "code": code, "status": status},
            ).scalar_one()
            if consent:
                connection.execute(
                    text(
                        "insert into public.programme_consents "
                        "(enrolment_id, purpose, consent_version, locale) "
                        "values (:enrolment, 'core', :version, 'en')"
                    ),
                    {"enrolment": enrolment, "version": _CONSENT_VERSION},
                )
        return enrolment

    def run(self, sql: str, **params: Any) -> Any:
        with self.admin.connect() as connection:
            return connection.execute(text(sql), params)

    def count(self, table: str, user: str) -> int:
        with self.admin.connect() as connection:
            return int(
                connection.execute(
                    text(f"select count(*) from public.{table} where user_id = :user"),
                    {"user": uuid.UUID(user)},
                ).scalar_one()
            )


@pytest.fixture
def seed(database: dict[str, Engine]) -> Seed:
    return Seed(database["admin"])


def _push(client: TestClient, user: str, *bundles: dict[str, Any]) -> Any:
    return client.post("/v1/sync/push", json={"areas": list(bundles)}, headers=auth(user))


def _pull(client: TestClient, user: str, cursor: int | None = None) -> dict[str, Any]:
    response = client.post("/v1/sync/pull", json={"cursor": cursor}, headers=auth(user))
    assert response.status_code == 200, response.text
    body: dict[str, Any] = response.json()
    return body


# --- Start-up role check -----------------------------------------------------


def test_the_sync_login_is_unprivileged(database: dict[str, Engine]) -> None:
    facts = login_role_facts(database["sync"])
    assert facts.session_user == "thsync"
    assert facts.member_of == ("authenticated",)
    assert facts.privileged == ()
    assert role_refusal(facts) is None


def test_start_up_refuses_a_superuser_login(
    database: dict[str, Engine], pg_settings: Settings
) -> None:
    with pytest.raises(StartupRefused, match="superuser"):
        with TestClient(create_app(settings=pg_settings, engine=database["admin"])):
            pass  # pragma: no cover - start-up must not get here


def test_start_up_refuses_a_login_holding_a_privileged_role(
    database: dict[str, Engine], pg_settings: Settings
) -> None:
    """A login that is not superuser itself but can become service_role."""
    login = f"thsync_test_{secrets.token_hex(4)}"
    password = secrets.token_hex(24)
    admin = database["admin"]
    _run_script(admin, f"create role {login} login noinherit password '{password}'")
    _run_script(admin, f"grant service_role, authenticated to {login}")
    engine = create_engine(
        database["sync"].url.set(username=login, password=password)
    )
    try:
        with pytest.raises(StartupRefused, match="service_role"):
            with TestClient(create_app(settings=pg_settings, engine=engine)):
                pass  # pragma: no cover - start-up must not get here
    finally:
        engine.dispose()
        _run_script(admin, f"drop role {login}")


# --- Round trip and identity -------------------------------------------------


def test_push_then_pull_round_trips_through_the_real_schema(
    pg_client: TestClient, seed: Seed
) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf")
    sent = bundle(
        "bf",
        lapses=[
            # An offset other than UTC comes back as the same instant in UTC.
            {"at": "2026-09-15T12:30:00.000+05:30", "severity": "minor", "context": ["stress"]}
        ],
    )
    pushed = _push(pg_client, alice, sent)
    assert pushed.status_code == 200, pushed.text
    assert pushed.json()["applied"] == ["bf"]

    body = _pull(pg_client, alice)
    assert body["current_areas"] == ["bf"]
    got = body["areas"][0]
    assert got["answers"] == sent["answers"]
    assert got["lapses"] == [
        {"at": "2026-09-15T07:00:00.000Z", "severity": "minor", "context": ["stress"]}
    ]
    assert seed.count("sync_answer", alice) == 1
    assert seed.count("sync_lapse", alice) == 1


def test_identity_is_transaction_local(
    pg_client: TestClient, seed: Seed, database: dict[str, Engine]
) -> None:
    """After a request the pooled connection is back to plain thsync, with no
    caller's claims left on it."""
    alice = seed.member()
    seed.enrol(alice, "bf")
    assert _push(pg_client, alice, bundle("bf")).status_code == 200
    with database["sync"].connect() as connection:
        row = connection.execute(
            text(
                "select current_user::text as role, "
                "coalesce(current_setting('request.jwt.claims', true), '') as claims"
            )
        ).one()
    assert row.role == "thsync"
    assert row.claims == ""


def test_row_level_security_scopes_every_statement(
    pg_client: TestClient, seed: Seed, database: dict[str, Engine]
) -> None:
    """Acting as Bob, the database itself hides Alice's rows — even from a query
    that forgot its `where` clause."""
    alice, bob = seed.member(), seed.member()
    seed.enrol(alice, "bf")
    assert _push(pg_client, alice, bundle("bf")).status_code == 200

    with transaction(database["sync"], uuid.UUID(bob)) as connection:
        for table in ("sync_account", "sync_area", "sync_answer", "sync_lapse"):
            assert connection.execute(text(f"select count(*) from public.{table}")).scalar_one() == 0
    with transaction(database["sync"], uuid.UUID(alice)) as connection:
        assert connection.execute(text("select count(*) from public.sync_answer")).scalar_one() == 1

    assert _pull(pg_client, bob)["areas"] == []
    assert _pull(pg_client, bob)["current_areas"] == []


def test_the_sync_session_cannot_update_lapses_or_delete_anything(
    pg_client: TestClient, seed: Seed, database: dict[str, Engine]
) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf")
    assert _push(pg_client, alice, bundle("bf")).status_code == 200
    for statement in (
        "update public.sync_lapse set severity = 'changed'",
        "delete from public.sync_lapse",
        "delete from public.sync_answer",
        "delete from public.sync_area",
        "delete from public.sync_account",
    ):
        with pytest.raises(DBAPIError) as raised:
            with transaction(database["sync"], uuid.UUID(alice)) as connection:
                connection.execute(text(statement))
        assert getattr(raised.value.orig, "sqlstate", None) == "42501", statement
    assert seed.count("sync_lapse", alice) == 1


# --- Refusals ----------------------------------------------------------------


def test_a_push_for_a_programme_with_no_enrolment_is_area_gone(
    pg_client: TestClient, seed: Seed
) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf")
    response = _push(pg_client, alice, bundle("bf"), bundle("ca"))
    assert response.status_code == 409
    assert response.json()["type"].endswith("/area_gone")
    assert response.json()["positions"] == [1]
    assert seed.count("sync_area", alice) == 0
    assert seed.count("sync_account", alice) == 0


def test_a_revoked_core_consent_refuses_the_push(pg_client: TestClient, seed: Seed) -> None:
    alice = seed.member()
    enrolment = seed.enrol(alice, "bf")
    seed.run(
        "update public.programme_consents set revoked_at = now() "
        "where enrolment_id = :enrolment and purpose = 'core'",
        enrolment=enrolment,
    )
    response = _push(pg_client, alice, bundle("bf"))
    assert response.status_code == 403
    assert response.json()["type"].endswith("/consent_required")
    assert seed.count("sync_area", alice) == 0


def test_an_enrolment_without_consent_refuses_the_push(pg_client: TestClient, seed: Seed) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf", consent=False)
    assert _push(pg_client, alice, bundle("bf")).status_code == 403


def test_a_left_programme_is_read_only(pg_client: TestClient, seed: Seed) -> None:
    alice = seed.member()
    enrolment = seed.enrol(alice, "bf")
    assert _push(pg_client, alice, bundle("bf")).status_code == 200
    seed.run("update public.enrolments set status = 'left' where id = :id", id=enrolment)

    response = _push(pg_client, alice, bundle("bf", base_revision=1, answers={}))
    assert response.status_code == 403
    body = _pull(pg_client, alice)
    assert body["current_areas"] == ["bf"]
    assert body["areas"][0]["answers"] != {}


def test_once_account_deletion_starts_nothing_more_is_written(
    pg_client: TestClient, seed: Seed
) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf")
    seed.run(
        "update public.profiles set account_deletion_started_at = now() where id = :id",
        id=uuid.UUID(alice),
    )
    response = _push(pg_client, alice, bundle("bf"))
    assert response.status_code == 403
    assert seed.count("sync_account", alice) == 0


def test_rls_refuses_a_write_the_service_check_would_have_allowed(
    pg_client: TestClient, seed: Seed, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Row-level security is the final word, not the service's own check.

    With the service's consent check forced open, a write for an enrolment
    with no core consent still fails inside the database, and nothing is
    stored.
    """
    alice = seed.member()
    seed.enrol(alice, "bf", consent=False)
    monkeypatch.setattr(repository, "_may_write", lambda *_: True)
    response = _push(pg_client, alice, bundle("bf"))
    assert response.status_code == 500
    assert seed.count("sync_area", alice) == 0
    assert seed.count("sync_answer", alice) == 0


# --- Deletion and lapses -----------------------------------------------------


def test_delete_now_cascades_and_reaches_the_other_device(
    pg_client: TestClient, seed: Seed
) -> None:
    alice = seed.member()
    bf = seed.enrol(alice, "bf")
    seed.enrol(alice, "nu")
    assert _push(pg_client, alice, bundle("bf"), bundle("nu")).status_code == 200
    synced = _pull(pg_client, alice)

    seed.run("delete from public.enrolments where id = :id", id=bf)

    later = _pull(pg_client, alice, synced["cursor"])
    assert later["current_areas"] == ["nu"]
    stale = _push(pg_client, alice, bundle("bf", base_revision=1))
    assert stale.status_code == 409
    assert stale.json()["type"].endswith("/area_gone")
    assert seed.count("sync_area", alice) == 1
    assert seed.count("sync_answer", alice) == 1
    assert seed.count("sync_lapse", alice) == 1


def test_a_changed_lapse_is_refused_and_a_collision_maps_to_409(
    pg_client: TestClient, seed: Seed, monkeypatch: pytest.MonkeyPatch
) -> None:
    alice = seed.member()
    seed.enrol(alice, "bf")
    first = {"at": "2026-09-15T07:00:00.000Z", "severity": "minor", "context": []}
    assert _push(pg_client, alice, bundle("bf", lapses=[first])).status_code == 200

    changed = _push(pg_client, alice, bundle("bf", base_revision=1, lapses=[{**first, "severity": "x"}]))
    assert changed.status_code == 409
    assert changed.json()["type"].endswith("/lapse_conflict")

    # A stale read makes the insert collide on the primary key (23505).
    real: Callable[..., Any] = repository._stored_lapses
    monkeypatch.setattr(repository, "_stored_lapses", lambda *args: real(*args)[:-1])
    second = {"at": "2026-09-16T07:00:00.000Z", "severity": "minor", "context": []}
    collided = _push(pg_client, alice, bundle("bf", base_revision=1, lapses=[second]))
    monkeypatch.undo()
    assert collided.status_code == 409, collided.text
    assert collided.json()["type"].endswith("/lapse_conflict")
    assert seed.count("sync_lapse", alice) == 1
    assert _pull(pg_client, alice)["areas"][0]["revision"] == 1
