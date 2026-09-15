"""Engine construction, and the two places the dialect actually matters.

The engine is synchronous, and the endpoints are therefore plain `def` rather
than `async def`, which makes Starlette run them on its thread pool. The async
alternative costs an `asyncpg`/greenlet stack for a workload of four small
indexed queries per request; the thread pool costs a thread. More to the point,
a synchronous `with engine.begin()` is a transaction whose extent you can see
by reading the function, and "did the revocation and the cursor bump commit
together" is a question this service has to be able to answer by inspection.
"""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any

from sqlalchemy import Engine, event, create_engine
from sqlalchemy.engine import Connection
from sqlalchemy.pool import StaticPool

from thsync.config import Settings
from thsync.schema import metadata

__all__ = ["create_engine_from_settings", "create_schema", "transaction"]


def create_engine_from_settings(settings: Settings) -> Engine:
    """Builds the engine for [settings].

    SQLite gets special treatment in two respects and Postgres in none:

    * an in-memory URL is given a [StaticPool] so that every connection is the
      same connection — otherwise each pooled connection gets a private, empty
      database and the schema appears to vanish between statements;
    * `PRAGMA foreign_keys=ON`, because SQLite ignores foreign keys by default
      and the cascade from `sync_area` to answers and lapses is what makes a
      test of deletion mean the same thing as production.
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
    """Creates the tables from `thsync.schema`.

    For tests and local development only. Production schema changes go through
    the `.sql` files in `migrations/`, which the deployment runner applies in
    filename order — running `create_all` against a real database would leave
    it with tables no migration has ever been applied to, and the next
    migration would then fail or, worse, not.
    """
    metadata.create_all(engine)


@contextmanager
def transaction(engine: Engine) -> Iterator[Connection]:
    """One transaction for one request.

    A push touching several areas commits or rolls back as a whole: a partial
    push would leave the account cursor ahead of the data it is supposed to
    describe, and the client would never ask for the missing part again.
    """
    with engine.begin() as connection:
        yield connection
