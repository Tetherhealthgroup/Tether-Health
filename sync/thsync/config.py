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

    #: The HS256 secret, for a project still on Supabase's legacy symmetric
    #: signing key. Empty when [jwt_jwks_url] is set.
    #:
    #: Exactly one of the two is configured, and that is enforced in
    #: [settings_from_env] rather than left to the verifier. Accepting either
    #: family at verification time — trying the secret, then the JWKS — is the
    #: algorithm confusion bug: an attacker signs HS256 using the *public* key's
    #: bytes as the shared secret, and a verifier willing to try both accepts
    #: it. Choosing the family from configuration, before any token arrives,
    #: means the token header never gets a vote.
    jwt_secret: str

    #: Where to fetch the signing keys for a project using asymmetric JWTs.
    #:
    #: Supabase issues ES256 (P-256) for new projects and publishes the public
    #: keys at `<project>/auth/v1/.well-known/jwks.json`, which needs no API
    #: key. Verifying against that is strictly better than a shared secret: the
    #: service never holds anything that could mint a token, so a compromise of
    #: this service cannot forge a session for somebody else.
    jwt_jwks_url: str | None

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

    secret = source.get(f"{_PREFIX}JWT_SECRET", "").strip()
    jwks_url = source.get(f"{_PREFIX}JWT_JWKS_URL", "").strip()
    issuer = source.get(f"{_PREFIX}JWT_ISSUER", "").strip()

    # One variable instead of three that have to agree.
    #
    # The issuer and the JWKS URL are both fixed functions of the project URL,
    # and asking for them separately invites a deployment where the issuer
    # names one project and the keys come from another — which fails closed,
    # but only after an outage nobody can explain.
    project = source.get(f"{_PREFIX}SUPABASE_URL", "").strip().rstrip("/")
    if project:
        issuer = issuer or f"{project}/auth/v1"
        jwks_url = jwks_url or f"{project}/auth/v1/.well-known/jwks.json"

    if bool(secret) == bool(jwks_url):
        # Neither, or both. Both is the dangerous one — see `Settings.jwt_secret`
        # for why the family must be chosen here and not per token — so it is
        # refused rather than resolved by precedence, which somebody would
        # later have to remember.
        raise ConfigError(
            f"configure exactly one of {_PREFIX}JWT_SECRET (legacy symmetric "
            f"projects) or {_PREFIX}SUPABASE_URL / {_PREFIX}JWT_JWKS_URL "
            "(asymmetric projects, which is what Supabase issues now). "
            f"{'Both were set.' if secret else 'Neither was set.'} There is no "
            "safe default: a generated secret would verify nothing and still "
            "return 200s, which looks exactly like a working deployment."
        )

    return Settings(
        database_url=source.get(f"{_PREFIX}DATABASE_URL", "sqlite+pysqlite:///./thsync.db"),
        jwt_secret=secret,
        jwt_jwks_url=jwks_url or None,
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
