"""Asymmetric token verification, which is what Supabase issues now.

New Supabase projects sign access tokens with ES256 and publish the public
keys at `<project>/auth/v1/.well-known/jwks.json`, unauthenticated. The legacy
shared HS256 secret still exists for older projects, so both are supported —
and the fact that both are supported is precisely what makes the algorithm
confusion test below the most important one in this file.

The key set is served from a real loopback HTTP server rather than by patching
`PyJWKClient`'s fetch. Patching would prove that the code calls a function;
serving proves it can fetch, parse and select a key from a document shaped the
way Supabase shapes one.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import threading
import time
from collections.abc import Iterator
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any

import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

from thsync.auth import verify_token
from thsync.config import ConfigError, Settings, settings_from_env
from thsync.problems import Problem

AUDIENCE = "authenticated"
ISSUER = "https://project.supabase.co/auth/v1"
SUBJECT = "11111111-1111-1111-1111-111111111111"
KID = "4d6f2069-6aba-421c-90e3-cd62073b3501"


@pytest.fixture(scope="module")
def signing_key() -> ec.EllipticCurvePrivateKey:
    """A P-256 key, the curve Supabase uses."""
    return ec.generate_private_key(ec.SECP256R1())


@pytest.fixture(scope="module")
def jwks_document(signing_key: ec.EllipticCurvePrivateKey) -> dict[str, Any]:
    public_jwk = json.loads(
        jwt.algorithms.ECAlgorithm.to_jwk(signing_key.public_key())
    )
    public_jwk.update({"kid": KID, "use": "sig", "alg": "ES256"})
    return {"keys": [public_jwk]}


@pytest.fixture(scope="module")
def jwks_url(jwks_document: dict[str, Any]) -> Iterator[str]:
    body = json.dumps(jwks_document).encode()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802 - name fixed by the base class
            self.send_response(200)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args: Any) -> None:
            """Silent. The default handler writes every request to stderr."""

    server = HTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    host, port = server.server_address[:2]
    # `server_address` is typed loosely; the host is a str for an AF_INET
    # socket and formatting bytes into a URL would silently produce "b'…'".
    yield f"http://{host!s}:{port}/auth/v1/.well-known/jwks.json"
    server.shutdown()
    server.server_close()


@pytest.fixture
def asymmetric_settings(jwks_url: str) -> Settings:
    return Settings(
        database_url="sqlite+pysqlite:///:memory:",
        jwt_secret="",
        jwt_jwks_url=jwks_url,
        jwt_audience=AUDIENCE,
        jwt_issuer=ISSUER,
        jwt_leeway_seconds=0,
        sql_echo=False,
    )


def _token(
    key: Any,
    *,
    algorithm: str = "ES256",
    kid: str | None = KID,
    expires_in: int = 3600,
    subject: str = SUBJECT,
) -> str:
    now = int(time.time())
    return jwt.encode(
        {
            "sub": subject,
            "aud": AUDIENCE,
            "iss": ISSUER,
            "iat": now,
            "exp": now + expires_in,
            "role": "authenticated",
        },
        key,
        algorithm=algorithm,
        headers={"kid": kid} if kid else None,
    )


def test_an_es256_token_is_accepted(
    signing_key: ec.EllipticCurvePrivateKey, asymmetric_settings: Settings
) -> None:
    account = verify_token(_token(signing_key), asymmetric_settings)
    assert account.id == SUBJECT


def test_an_es256_token_signed_by_a_stranger_is_refused(
    asymmetric_settings: Settings,
) -> None:
    other = ec.generate_private_key(ec.SECP256R1())
    with pytest.raises(Problem) as raised:
        verify_token(_token(other), asymmetric_settings)
    assert raised.value.status_code == 401


def test_the_algorithm_in_the_header_gets_no_vote(
    jwks_document: dict[str, Any], asymmetric_settings: Settings
) -> None:
    """The algorithm confusion attack, refused.

    The classic break: the verifier is configured with a *public* key, so an
    attacker signs an HS256 token using that key's own published bytes as the
    shared secret. A verifier that honours the token header's `alg` computes
    the same HMAC and accepts it — and the key is public, so anyone can do it.

    This must fail because the algorithm list comes from configuration, never
    from the token.
    """
    # Assembled by hand rather than with `jwt.encode`, which refuses to sign
    # when the HMAC secret looks like a key — a guard on the *signing* side
    # that would stop the forgery before it ever reached the verifier and
    # leave this test proving nothing. A real attacker has no such guard, so
    # neither does this.
    published = jwt.algorithms.ECAlgorithm.from_jwk(
        json.dumps(jwks_document["keys"][0])
    )
    assert isinstance(published, ec.EllipticCurvePublicKey)
    public_pem = published.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    def segment(value: dict[str, Any]) -> bytes:
        return base64.urlsafe_b64encode(
            json.dumps(value, separators=(",", ":")).encode()
        ).rstrip(b"=")

    signing_input = b".".join(
        [
            segment({"alg": "HS256", "typ": "JWT", "kid": KID}),
            segment(
                {
                    "sub": "22222222-2222-2222-2222-222222222222",
                    "aud": AUDIENCE,
                    "iss": ISSUER,
                    "exp": int(time.time()) + 3600,
                }
            ),
        ]
    )
    signature = base64.urlsafe_b64encode(
        hmac.new(public_pem, signing_input, hashlib.sha256).digest()
    ).rstrip(b"=")
    forged = (signing_input + b"." + signature).decode()

    # Sanity: the signature really is a correct HS256 MAC over this token,
    # computed with the published key. Without this the test could pass
    # because the forgery was malformed rather than because the algorithm
    # pinning worked. Checked by recomputing the MAC rather than with
    # `jwt.decode`, which refuses a key-shaped HMAC secret on the verify side
    # too — a guard this service does not rely on and must not be tested
    # through.
    assert hmac.compare_digest(
        signature,
        base64.urlsafe_b64encode(
            hmac.new(public_pem, signing_input, hashlib.sha256).digest()
        ).rstrip(b"="),
    )
    assert json.loads(base64.urlsafe_b64decode(forged.split(".")[0] + "=="))[
        "alg"
    ] == "HS256"

    with pytest.raises(Problem) as raised:
        verify_token(forged, asymmetric_settings)
    assert raised.value.status_code == 401


def test_a_token_naming_an_unknown_key_is_refused(
    signing_key: ec.EllipticCurvePrivateKey, asymmetric_settings: Settings
) -> None:
    with pytest.raises(Problem) as raised:
        verify_token(_token(signing_key, kid="not-a-key-we-know"), asymmetric_settings)
    assert raised.value.status_code == 401


def test_an_expired_token_is_refused(
    signing_key: ec.EllipticCurvePrivateKey, asymmetric_settings: Settings
) -> None:
    with pytest.raises(Problem) as raised:
        verify_token(_token(signing_key, expires_in=-60), asymmetric_settings)
    assert raised.value.status_code == 401


def test_an_unreachable_key_set_fails_closed() -> None:
    """A 401, not a 500, and certainly not an accepted token."""
    settings = Settings(
        database_url="sqlite+pysqlite:///:memory:",
        jwt_secret="",
        # Port 1 on loopback: nothing listens, and it fails fast.
        jwt_jwks_url="http://127.0.0.1:1/jwks.json",
        jwt_audience=AUDIENCE,
        jwt_issuer=ISSUER,
        jwt_leeway_seconds=0,
        sql_echo=False,
    )
    key = ec.generate_private_key(ec.SECP256R1())
    with pytest.raises(Problem) as raised:
        verify_token(_token(key), settings)
    assert raised.value.status_code == 401


class TestConfiguration:
    def test_the_project_url_derives_the_issuer_and_the_key_set(self) -> None:
        settings = settings_from_env(
            {"THSYNC_SUPABASE_URL": "https://gcsazvotzqvjayqnqyra.supabase.co"}
        )
        assert settings.jwt_issuer == (
            "https://gcsazvotzqvjayqnqyra.supabase.co/auth/v1"
        )
        assert settings.jwt_jwks_url == (
            "https://gcsazvotzqvjayqnqyra.supabase.co/auth/v1/.well-known/jwks.json"
        )
        assert settings.jwt_secret == ""

    def test_a_trailing_slash_does_not_double_up(self) -> None:
        settings = settings_from_env(
            {"THSYNC_SUPABASE_URL": "https://example.supabase.co/"}
        )
        assert settings.jwt_issuer == "https://example.supabase.co/auth/v1"

    def test_configuring_both_families_is_refused(self) -> None:
        # Refused rather than resolved by precedence. Accepting both is the
        # algorithm confusion bug at the configuration layer, and a precedence
        # rule is something somebody has to remember at three in the morning.
        with pytest.raises(ConfigError):
            settings_from_env(
                {
                    "THSYNC_JWT_SECRET": "a" * 40,
                    "THSYNC_SUPABASE_URL": "https://example.supabase.co",
                }
            )

    def test_configuring_neither_is_refused(self) -> None:
        with pytest.raises(ConfigError):
            settings_from_env({})

    def test_the_legacy_secret_still_works_on_its_own(self) -> None:
        settings = settings_from_env({"THSYNC_JWT_SECRET": "a" * 40})
        assert settings.jwt_jwks_url is None
        assert settings.jwt_secret == "a" * 40
