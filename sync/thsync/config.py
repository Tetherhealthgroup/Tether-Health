"""Configuration, read once from the environment at start-up.

A frozen dataclass built by an explicit function rather than a settings object
that reads `os.environ` lazily. The difference matters at exactly one moment:
start-up. A lazy reader turns a missing `THSYNC_JWT_SECRET` into a 500 on the
first authenticated request — in production that is a service that came up
green, passed its health check, and rejects everybody. This raises before the
app object exists, so the process dies at deploy time where somebody is
watching.
"""

from __future__ import annotations

import os
from collections.abc import Mapping
from dataclasses import dataclass

__all__ = ["Settings", "settings_from_env", "ConfigError"]

_PREFIX = "THSYNC_"


class ConfigError(RuntimeError):
    """Raised when the environment cannot produce a usable [Settings]."""


@dataclass(frozen=True, slots=True)
class Settings:
    """Everything the service needs to know that is not in the database."""

    #: SQLAlchemy URL. `postgresql+psycopg://…` in production, a SQLite URL in
    #: tests. Nothing in this codebase branches on the dialect except the two
    #: places that have to (see `thsync.db`).
    database_url: str

    #: The HS256 secret Supabase signs access tokens with. There is no
    #: asymmetric option here on purpose: Supabase's legacy JWT secret is
    #: symmetric, and accepting *either* family would mean accepting whichever
    #: one an attacker names in the token header, which is the algorithm
    #: confusion bug rather than a feature.
    jwt_secret: str

    #: `aud` every token must carry. Supabase issues `authenticated` for a
    #: signed-in user and `anon` for the public key, and those two are the same
    #: signature — the audience check is the only thing that keeps an anonymous
    #: token out.
    jwt_audience: str

    #: `iss` to require, or None to skip the check. Optional because a
    #: self-hosted Supabase names itself by its own URL and there is no useful
    #: default to guess.
    jwt_issuer: str | None

    #: Clock skew tolerated on `exp`/`iat`. Small: a phone with a wrong clock
    #: should re-authenticate, not be granted a longer session.
    jwt_leeway_seconds: int

    #: Echo SQL. Off by default and dangerous to turn on in production —
    #: parameters include answer text.
    sql_echo: bool


def settings_from_env(env: Mapping[str, str] | None = None) -> Settings:
    """Builds [Settings] from `THSYNC_*` variables.

    [env] is injectable so a test can build settings without mutating the
    process environment, which is global state that leaks between tests.
    """
    source = os.environ if env is None else env

    secret = source.get(f"{_PREFIX}JWT_SECRET", "")
    if not secret:
        # Not defaulted, not generated. A generated secret would verify nothing
        # and still return 200s, which looks exactly like a working deployment.
        raise ConfigError(
            f"{_PREFIX}JWT_SECRET is required; it is the Supabase JWT secret "
            "and there is no safe default for it."
        )

    issuer = source.get(f"{_PREFIX}JWT_ISSUER", "").strip()

    return Settings(
        database_url=source.get(f"{_PREFIX}DATABASE_URL", "sqlite+pysqlite:///./thsync.db"),
        jwt_secret=secret,
        jwt_audience=source.get(f"{_PREFIX}JWT_AUDIENCE", "authenticated"),
        jwt_issuer=issuer or None,
        jwt_leeway_seconds=_int(source, f"{_PREFIX}JWT_LEEWAY_SECONDS", 10),
        sql_echo=_bool(source, f"{_PREFIX}SQL_ECHO", False),
    )


def _int(source: Mapping[str, str], name: str, fallback: int) -> int:
    raw = source.get(name)
    if raw is None or raw == "":
        return fallback
    try:
        return int(raw)
    except ValueError as error:
        raise ConfigError(f"{name} must be an integer; got {raw!r}.") from error


def _bool(source: Mapping[str, str], name: str, fallback: bool) -> bool:
    raw = source.get(name)
    if raw is None or raw == "":
        return fallback
    return raw.strip().lower() in {"1", "true", "yes", "on"}
