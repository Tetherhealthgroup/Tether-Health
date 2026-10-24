"""The application factory.

A factory rather than a module-level `app = FastAPI()`, because the test suite
needs an app per database and a module-level app would share one engine across
every test in the process — which is how a test that passes alone fails in a
suite.
"""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import Engine

from thsync import __version__
from thsync.api import router
from thsync.config import Settings, settings_from_env
from thsync.db import create_engine_from_settings
from thsync.problems import install_problem_handlers

__all__ = ["create_app"]

_DESCRIPTION = """
Syncs a Tether Health session between a person's devices, one programme at a
time. The unit of transfer, of versioning, of conflict and of deletion is a
single programme's bundle — never the whole record.
""".strip()


def create_app(settings: Settings | None = None, engine: Engine | None = None) -> FastAPI:
    """Builds the application.

    [engine] is injectable so that tests can hand in a SQLite engine whose
    lifetime they control. When it is None the app owns one, opened at
    start-up and disposed at shutdown — opening it at import time would make
    the module unimportable without a reachable database, which breaks
    `--help`, schema generation, and every offline tool.
    """
    resolved = settings or settings_from_env()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        if engine is None:
            app.state.engine = create_engine_from_settings(resolved)
        try:
            yield
        finally:
            if engine is None:
                app.state.engine.dispose()

    app = FastAPI(
        title="Tether Health sync",
        version=__version__,
        description=_DESCRIPTION,
        lifespan=lifespan,
        # The interactive docs post real bodies against whatever the browser is
        # pointed at, and the bodies here are treatment records. Disabled by
        # default; the OpenAPI document itself is still served for tooling.
        docs_url=None,
        redoc_url=None,
    )
    app.state.settings = resolved
    # An injected engine is attached here rather than in the lifespan, because
    # a caller who supplied one already owns its lifetime — and because a test
    # client that never runs the lifespan would otherwise find no engine at all.
    if engine is not None:
        app.state.engine = engine
    install_problem_handlers(app)
    app.include_router(router)
    return app
