"""Engine construction, the per-transaction identity, and the start-up role check.

The engine is synchronous, and the endpoints are therefore plain `def` rather
than `async def`, which makes Starlette run them on its thread pool. The async
alternative costs an `asyncpg`/greenlet stack for a workload of a few small
indexed queries per request; the thread pool costs a thread. More to the point,
a synchronous `with engine.begin()` is a transaction whose extent you can see
by reading the function.

**How the service acts as the caller on PostgreSQL.** It logs in as the role
`thsync`, which owns nothing, holds no privileges of its own and is a member of
`authenticated` only. Every transaction starts with

    SET LOCAL ROLE authenticated;
    SELECT set_config('request.jwt.claims', '{"sub": "<verified sub>", ...}', true);

so the database applies the same `auth.uid()` row-level security policies it
applies to a request through PostgREST, and the sync tables' write policies
(which also require `session_user = 'thsync'`) let the write through. Both
settings are transaction-local: they end at commit or rollback, so a pooled
connection never carries one caller's identity into the next transaction.
"""

from __future__ import annotations

import json
import uuid
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Final

from sqlalchemy import Engine, create_engine, event, text
from sqlalchemy.engine import Connection
from sqlalchemy.pool import StaticPool

from thsync.config import ConfigError, Settings
from thsync.schema import metadata

__all__ = [
    "LOGIN_ROLE",
    "RoleFacts",
    "StartupRefused",
    "check_login_role",
    "create_engine_from_settings",
    "create_schema",
    "login_role_facts",
    "read_role_facts",
    "role_refusal",
    "transaction",
]

#: The only role this service may log in as on PostgreSQL. The sync tables'
#: write policies require `session_user = 'thsync'`, and the check is exact: a
#: superuser or the PostgREST login role can never satisfy it.
LOGIN_ROLE: Final = "thsync"

#: Roles whose privileges defeat row-level security or the sync-only
#: restriction. Holding any of them, directly or through membership, refuses
#: start-up.
_PRIVILEGED_ROLES: Final = (
    "postgres",
    "service_role",
    "supabase_admin",
    "pg_read_all_data",
    "pg_write_all_data",
)


class StartupRefused(ConfigError):
    """The database login is not the unprivileged sync role."""


def create_engine_from_settings(settings: Settings) -> Engine:
    """Builds the engine for [settings].

    SQLite gets special treatment in two respects and Postgres in none:

    * an in-memory URL is given a [StaticPool] so that every connection is the
      same connection — otherwise each pooled connection gets a private, empty
      database and the schema appears to vanish between statements;
    * `PRAGMA foreign_keys=ON`, because SQLite ignores foreign keys by default
      and the cascade from `enrolments` to `sync_area` to answers and lapses is
      what makes a test of deletion mean the same thing as production.
    """
    kwargs: dict[str, Any] = {
        "echo": settings.sql_echo,
        "future": True,
        # Not a debugging preference. SQLAlchemy puts the bound parameters into
        # the text of a `StatementError`, and the bound parameters of this
        # service are answer text and lapse context. Without this, one
        # constraint violation writes a person's free-text answer into the
        # application log via the traceback — the single most likely way PHI
        # escapes from here.
        "hide_parameters": True,
    }
    url = settings.database_url

    if url.startswith("sqlite"):
        kwargs["connect_args"] = {"check_same_thread": False}
        if ":memory:" in url or "mode=memory" in url:
            kwargs["poolclass"] = StaticPool
    else:
        # Connections are held open across requests; `pre_ping` turns a
        # connection killed by a proxy or a failover into a reconnect instead
        # of a 500 on somebody's next sync.
        kwargs["pool_pre_ping"] = True

    engine = create_engine(url, **kwargs)

    if engine.dialect.name == "sqlite":

        @event.listens_for(engine, "connect")
        def _enforce_foreign_keys(dbapi_connection: Any, _: Any) -> None:
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()

    return engine


def create_schema(engine: Engine) -> None:
    """Creates the tables from `thsync.schema` on a SQLite database.

    For tests and local development only, and refused anywhere else. On
    PostgreSQL the schema comes from `supabase/migrations/`, with the row-level
    security, grants and triggers this metadata does not describe; tables made
    by `create_all` would have none of them.
    """
    if engine.dialect.name != "sqlite":
        raise ConfigError(
            "create_schema is for SQLite only; PostgreSQL schema comes from "
            "supabase/migrations"
        )
    metadata.create_all(engine)


@contextmanager
def transaction(engine: Engine, user_id: uuid.UUID) -> Iterator[Connection]:
    """One transaction for one request, acting as [user_id].

    A push touching several areas commits or rolls back as a whole: a partial
    push would leave the account cursor ahead of the data it is supposed to
    describe, and the client would never ask for the missing part again.

    On PostgreSQL the transaction first takes the caller's identity (see the
    module docstring). [user_id] is the verified token subject; it reaches the
    database as a bound parameter inside a JSON document, never as SQL text.
    """
    with engine.begin() as connection:
        if connection.dialect.name == "postgresql":
            _act_as(connection, user_id)
        yield connection


def _act_as(connection: Connection, user_id: uuid.UUID) -> None:
    claims = json.dumps({"sub": str(user_id), "role": "authenticated"})
    connection.execute(text("set local role authenticated"))
    # `request.jwt.claim.sub` is cleared so that only the claims document
    # names the caller; auth.uid() would otherwise prefer a stale value.
    connection.execute(
        text(
            "select set_config('request.jwt.claim.sub', '', true), "
            "set_config('request.jwt.claims', :claims, true)"
        ),
        {"claims": claims},
    )


@dataclass(frozen=True, slots=True)
class RoleFacts:
    """What the database says about the login this service is using."""

    session_user: str
    current_user: str
    superuser: bool
    bypass_rls: bool
    #: Can create, alter or drop roles (`rolcreaterole`).
    create_role: bool
    #: Can open replication connections (`rolreplication`).
    replication: bool
    #: Roles the login is a direct member of.
    member_of: tuple[str, ...]
    #: Privileged roles (from [_PRIVILEGED_ROLES]) the login can act as,
    #: directly or through membership.
    privileged: tuple[str, ...]


def read_role_facts(connection: Connection) -> RoleFacts:
    """Reads [RoleFacts] for the current PostgreSQL session."""
    row = connection.execute(
        text(
            """
            select
              session_user::text as session_user,
              current_user::text as current_user,
              s.rolsuper or c.rolsuper as superuser,
              s.rolbypassrls or c.rolbypassrls as bypass_rls,
              s.rolcreaterole or c.rolcreaterole as create_role,
              s.rolreplication or c.rolreplication as replication,
              coalesce(
                (select array_agg(m.roleid::regrole::text order by m.roleid::regrole::text)
                 from pg_catalog.pg_auth_members as m
                 where m.member = s.oid),
                '{}'
              ) as member_of,
              coalesce(
                (select array_agg(p.rolname::text order by p.rolname::text)
                 from pg_catalog.pg_roles as p
                 where p.rolname = any (cast(:privileged as text[]))
                   and pg_catalog.pg_has_role(s.oid, p.oid, 'MEMBER')),
                '{}'
              ) as privileged
            from pg_catalog.pg_roles as s, pg_catalog.pg_roles as c
            where s.rolname = session_user and c.rolname = current_user
            """
        ),
        {"privileged": list(_PRIVILEGED_ROLES)},
    ).one()
    return RoleFacts(
        session_user=str(row.session_user),
        current_user=str(row.current_user),
        superuser=bool(row.superuser),
        bypass_rls=bool(row.bypass_rls),
        create_role=bool(row.create_role),
        replication=bool(row.replication),
        member_of=tuple(str(name) for name in row.member_of),
        privileged=tuple(str(name) for name in row.privileged),
    )


def role_refusal(facts: RoleFacts) -> str | None:
    """Why the service must not start with this login, or None if it may.

    Each condition alone is enough to refuse. A superuser or a `BYPASSRLS`
    role would read and write every person's rows regardless of policy; a role
    that can create roles or replicate holds powers beyond its own grants; a
    login other than `thsync` cannot write sync data at all (the policies check
    `session_user`) and is almost certainly a privileged role pasted into the
    wrong variable; and a role set at session level, or membership in anything
    beyond `authenticated`, gives the service privileges it was designed not to
    hold.
    """
    if facts.superuser:
        return "the database login is a superuser"
    if facts.bypass_rls:
        return "the database login bypasses row-level security"
    if facts.create_role:
        return "the database login can create roles"
    if facts.replication:
        return "the database login can replicate"
    if facts.privileged:
        return "the database login can act as a privileged role: " + ", ".join(facts.privileged)
    if facts.session_user != LOGIN_ROLE:
        return f"the database login must be the role {LOGIN_ROLE}, not {facts.session_user}"
    if facts.current_user != facts.session_user:
        return "the database session has a role set at session level"
    if facts.member_of != ("authenticated",):
        return "the database login must be a member of authenticated only"
    return None


def check_login_role(engine: Engine) -> None:
    """Refuses to start unless the PostgreSQL login is the unprivileged sync role.

    Runs once at start-up, before the first request. No-op for SQLite, which
    production refuses in configuration (`thsync.config`).
    """
    if engine.dialect.name != "postgresql":
        return
    reason = role_refusal(login_role_facts(engine))
    if reason is not None:
        raise StartupRefused(f"refusing to start: {reason}.")


def login_role_facts(engine: Engine) -> RoleFacts:
    """[RoleFacts] for a fresh connection from [engine]."""
    with engine.connect() as connection:
        return read_role_facts(connection)
