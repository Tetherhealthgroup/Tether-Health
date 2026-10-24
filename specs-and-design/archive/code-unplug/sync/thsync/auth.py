"""Bearer token verification.

The account id comes from the verified `sub` claim and from nowhere else. There
is no account id in any path, body, or query parameter in this API — not
because it would be inconvenient to check one, but because a parameter that is
*usually* checked is the shape this class of bug takes. With no such parameter
there is no code path to forget.
"""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Any, Final

import jwt
from fastapi import Request, status
from jwt import PyJWKClient

from thsync.config import Settings
from thsync.logs import log
from thsync.problems import Problem

__all__ = ["Account", "verify_token", "account_from_request"]

#: Pinned per key family, never taken from the token.
#:
#: PyJWT will otherwise honour the `alg` in the token header, which lets a
#: caller present `{"alg":"none"}`, or sign an HS256 token using the *public*
#: key's bytes as the shared secret and have it verify. Which list applies is
#: decided by configuration before any token is seen — see
#: `Settings.jwt_secret` — so the two never overlap and the header never gets
#: a vote.
_SYMMETRIC: Final = ["HS256"]

#: What Supabase issues for projects on asymmetric keys. ES256 is the current
#: default (P-256); RS256 appears on projects migrated from older setups.
_ASYMMETRIC: Final = ["ES256", "RS256"]

#: Claims that must be present. `sub` is the account; without `exp` a leaked
#: token never stops working.
_REQUIRED_CLAIMS: Final = ["exp", "sub", "aud"]

_SCHEME: Final = "bearer"

_CHALLENGE: Final = {"WWW-Authenticate": "Bearer"}

#: How long a fetched key set is trusted before it is refetched. Supabase key
#: rotation is rare and an unknown `kid` forces a refetch anyway, so this only
#: bounds how long a *revoked* key stays usable.
_JWKS_LIFESPAN_SECONDS: Final = 600


@dataclass(frozen=True, slots=True)
class Account:
    """The authenticated caller. `id` is the verified `sub`."""

    id: str


def verify_token(token: str, settings: Settings) -> Account:
    """Verifies [token] and returns the account it names.

    Raises [Problem] with 401 on anything wrong. The detail says which of
    signature, expiry or audience failed, because that distinction tells a
    client whether to refresh the token or to sign the person in again, and it
    reveals nothing an unauthenticated caller could not establish by trying.
    What it never contains is the token, a claim value, or the account id.
    """
    try:
        key, algorithms = _key_for(token, settings)
    except Problem:
        raise
    except Exception:
        # Fetching the JWKS failed: DNS, TLS, a 500 from Supabase. This is the
        # one authentication failure that is not the caller's fault, and it is
        # still answered as 401 rather than 503 — telling an unauthenticated
        # caller about the state of our key infrastructure buys them a probe
        # and buys us nothing. Logged, so it is visible on our side.
        log.warning("could not obtain a signing key for token verification")
        raise _unauthenticated(
            "invalid-token", "The access token could not be verified."
        ) from None

    try:
        claims: dict[str, Any] = jwt.decode(
            token,
            key,
            algorithms=algorithms,
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
            leeway=settings.jwt_leeway_seconds,
            options={"require": _REQUIRED_CLAIMS, "verify_aud": True},
        )
    except jwt.ExpiredSignatureError:
        raise _unauthenticated("expired-token", "The access token has expired.") from None
    except jwt.InvalidAudienceError:
        raise _unauthenticated(
            "invalid-token", "The access token was not issued for this service."
        ) from None
    except jwt.InvalidIssuerError:
        raise _unauthenticated(
            "invalid-token", "The access token was not issued by the expected issuer."
        ) from None
    except jwt.MissingRequiredClaimError:
        raise _unauthenticated(
            "invalid-token", "The access token is missing a required claim."
        ) from None
    except jwt.InvalidTokenError:
        # The catch-all, and deliberately the least specific message: a bad
        # signature and a malformed token are told apart by PyJWT but must not
        # be told apart by a caller, or the error becomes a signature oracle.
        raise _unauthenticated("invalid-token", "The access token could not be verified.") from None

    subject = claims.get("sub")
    if not isinstance(subject, str) or not subject.strip():
        # `require` proves `sub` is present, not that it is a usable id. An
        # empty or non-string subject would scope every query to the same
        # falsy account, which is the worst possible failure in this service.
        raise _unauthenticated("invalid-token", "The access token names no subject.")

    return Account(id=subject.strip())


@lru_cache(maxsize=8)
def _jwk_client(url: str) -> PyJWKClient:
    """One client per JWKS URL, kept for the life of the process.

    `PyJWKClient` caches the key set and only refetches when a token arrives
    with an unknown `kid`, which is exactly the behaviour a rotation needs: no
    network call on the hot path, and no stale-key outage when Supabase rolls
    a key. Building a fresh client per request would fetch the JWKS per
    request, turning every sync into two round trips and Supabase's auth
    endpoint into a hard dependency of ours.

    Cached on the URL rather than on `Settings` because `Settings` is not
    hashable and the URL is the only part that identifies the key set.
    """
    return PyJWKClient(url, cache_keys=True, lifespan=_JWKS_LIFESPAN_SECONDS)


def _key_for(token: str, settings: Settings) -> tuple[Any, list[str]]:
    """The verification key and the algorithms allowed with it.

    Returns the pair together so the two can never be mismatched by a caller —
    handing back a public key and letting somebody else pick the algorithm
    list is how algorithm confusion gets reintroduced.
    """
    if settings.jwt_jwks_url is None:
        return settings.jwt_secret, list(_SYMMETRIC)
    signing_key = _jwk_client(settings.jwt_jwks_url).get_signing_key_from_jwt(token)
    return signing_key.key, list(_ASYMMETRIC)


def account_from_request(request: Request, settings: Settings) -> Account:
    """Pulls the bearer token out of [request] and verifies it."""
    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != _SCHEME or not token.strip():
        raise _unauthenticated(
            "unauthenticated", "A bearer access token is required on this endpoint."
        )
    account = verify_token(token.strip(), settings)
    log.debug("authenticated account=%s", account.id)
    return account


def _unauthenticated(code: str, detail: str) -> Problem:
    # Logged at info without the reason's specifics beyond the code: a failed
    # auth is worth counting, and the code is enough to tell a clock-skew
    # outage from a credential-stuffing run.
    log.info("authentication rejected: %s", code)
    return Problem(
        status_code=status.HTTP_401_UNAUTHORIZED,
        code=code,
        title="Not authenticated",
        detail=detail,
        headers=dict(_CHALLENGE),
    )
