"""Bearer token verification.

The account id comes from the verified `sub` claim and from nowhere else. There
is no account id in any path, body, or query parameter in this API — not
because it would be inconvenient to check one, but because a parameter that is
*usually* checked is the shape this class of bug takes. With no such parameter
there is no code path to forget.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Final

import jwt
from fastapi import Request, status

from thsync.config import Settings
from thsync.logs import log
from thsync.problems import Problem

__all__ = ["Account", "verify_token", "account_from_request"]

#: Pinned, and a list of exactly one. PyJWT will otherwise honour the `alg` in
#: the token header, which lets a caller present `{"alg":"none"}` or sign an
#: RS256 token with the HS256 secret's bytes as a public key. Supabase's legacy
#: signing key is symmetric HS256; nothing else is accepted here.
_ALGORITHMS: Final = ["HS256"]

#: Claims that must be present. `sub` is the account; without `exp` a leaked
#: token never stops working.
_REQUIRED_CLAIMS: Final = ["exp", "sub", "aud"]

_SCHEME: Final = "bearer"

_CHALLENGE: Final = {"WWW-Authenticate": "Bearer"}


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
        claims: dict[str, Any] = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=_ALGORITHMS,
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
