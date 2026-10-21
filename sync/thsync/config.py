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
from typing import Final, Literal

__all__ = ["Environment", "Settings", "settings_from_env", "ConfigError"]

_PREFIX = "THSYNC_"

Environment = Literal["production", "development"]

#: What an unset `THSYNC_ENVIRONMENT` means. Production, so that a deployment
#: that forgets the variable gets the strict rules rather than the lenient
#: ones; local work sets `development` explicitly.
_DEFAULT_ENVIRONMENT: Final[Environment] = "production"


class ConfigError(RuntimeError):
    """Raised when the environment cannot produce a usable [Settings]."""


@dataclass(frozen=True, slots=True)
class Settings:
    """Everything the service needs to know that is not in the database."""

    #: SQLAlchemy URL. `postgresql+psycopg://…` in production (required), a
    #: SQLite URL in most tests. Dialect branches live in `thsync.db` and in
    #: the one consent check in `thsync.repository`.
    database_url: str

    #: The HS256 secret, for local work against a project still on
    #: Supabase's legacy symmetric signing key. Empty when [jwt_jwks_url] is
    #: set, and always empty in production, which refuses it.
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

    #: Echo SQL. Off by default, and always off in production: parameters
    #: include answer text.
    sql_echo: bool

    #: `production` or `development`. Production accepts only asymmetric
    #: (JWKS) token verification, only a PostgreSQL database, and never echoes
    #: SQL. Defaults to production; see [settings_from_env].
    environment: Environment = _DEFAULT_ENVIRONMENT


def settings_from_env(env: Mapping[str, str] | None = None) -> Settings:
    """Builds [Settings] from `THSYNC_*` variables.

    [env] is injectable so a test can build settings without mutating the
    process environment, which is global state that leaks between tests.
    """
    source = os.environ if env is None else env

    environment = _environment(source)
    production = environment == "production"

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

    if production and secret:
        # A shared secret can mint a token for anybody, so a service holding
        # one is a service whose compromise forges sessions. Production
        # verifies against the project's published public keys only.
        raise ConfigError(
            f"{_PREFIX}JWT_SECRET is refused in production. Configure "
            f"{_PREFIX}SUPABASE_URL (or {_PREFIX}JWT_JWKS_URL) so tokens are "
            "verified with the project's public keys (ES256)."
        )

    if bool(secret) == bool(jwks_url):
        # Neither, or both. Both is the dangerous one — see `Settings.jwt_secret`
        # for why the family must be chosen here and not per token — so it is
        # refused rather than resolved by precedence, which somebody would
        # later have to remember.
        raise ConfigError(
            f"configure exactly one of {_PREFIX}JWT_SECRET (legacy symmetric "
            f"projects, development only) or {_PREFIX}SUPABASE_URL / "
            f"{_PREFIX}JWT_JWKS_URL (asymmetric projects, which is what "
            f"Supabase issues now). {'Both were set.' if secret else 'Neither was set.'} "
            "There is no safe default: a generated secret would verify nothing "
            "and still return 200s, which looks exactly like a working deployment."
        )

    database_url = source.get(f"{_PREFIX}DATABASE_URL", "").strip()
    if production and not database_url.startswith("postgresql"):
        # The start-up role check, row-level security and the per-transaction
        # claims all exist only on PostgreSQL. A production service on any
        # other database would run with none of them.
        raise ConfigError(
            f"{_PREFIX}DATABASE_URL must be a postgresql+psycopg:// URL in "
            "production."
        )

    return Settings(
        database_url=database_url or "sqlite+pysqlite:///./thsync.db",
        jwt_secret=secret,
        jwt_jwks_url=jwks_url or None,
        jwt_audience=source.get(f"{_PREFIX}JWT_AUDIENCE", "authenticated"),
        jwt_issuer=issuer or None,
        jwt_leeway_seconds=_int(source, f"{_PREFIX}JWT_LEEWAY_SECONDS", 10),
        # Forced off in production whatever the variable says: an echoed
        # statement carries its parameters, and those are answer text.
        sql_echo=False if production else _bool(source, f"{_PREFIX}SQL_ECHO", False),
        environment=environment,
    )


def _environment(source: Mapping[str, str]) -> Environment:
    raw = source.get(f"{_PREFIX}ENVIRONMENT", "").strip().lower()
    if raw == "":
        return _DEFAULT_ENVIRONMENT
    if raw == "production":
        return "production"
    if raw == "development":
        return "development"
    raise ConfigError(
        f"{_PREFIX}ENVIRONMENT must be 'production' or 'development'; got {raw!r}."
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
