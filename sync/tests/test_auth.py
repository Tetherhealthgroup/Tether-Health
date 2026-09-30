"""Token verification, one broken claim at a time."""

from __future__ import annotations

import time

import jwt
import pytest
from fastapi.testclient import TestClient

from conftest import ALICE, AUDIENCE, ISSUER, JWT_SECRET, auth, bundle, token

PROTECTED = [
    ("POST", "/v1/sync/pull", {"cursor": None}),
    ("POST", "/v1/sync/push", {"areas": [bundle()]}),
    ("DELETE", "/v1/sync/areas/tobacco", None),
    ("DELETE", "/v1/sync/account", None),
]


@pytest.mark.parametrize(("method", "path", "body"), PROTECTED)
def test_every_sync_endpoint_requires_a_token(
    client: TestClient, method: str, path: str, body: dict[str, object] | None
) -> None:
    response = client.request(method, path, json=body)
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"
    assert response.headers["content-type"].startswith("application/problem+json")


def test_a_valid_token_is_accepted(client: TestClient) -> None:
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).status_code == 200


def test_an_expired_token_is_refused(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers=auth(expires_in=-60)
    )
    assert response.status_code == 401
    assert response.json()["type"].endswith("/expired-token")
    # The distinction matters to the client: refresh, do not re-authenticate.
    assert "expired" in response.json()["detail"].lower()


def test_a_token_signed_with_the_wrong_secret_is_refused(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/pull",
        json={"cursor": None},
        headers=auth(secret="not-the-secret-0123456789abcdefghij"),
    )
    assert response.status_code == 401
    assert response.json()["type"].endswith("/invalid-token")
    # Deliberately indistinguishable from a malformed token: telling the two
    # apart turns this endpoint into a signature oracle.
    assert response.json()["detail"] == "The access token could not be verified."


def test_a_token_for_another_audience_is_refused(client: TestClient) -> None:
    """Supabase signs `anon` tokens with the same key as `authenticated` ones.

    The audience check is the only thing standing between the public anon key
    and every account's record.
    """
    response = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(audience="anon"))
    assert response.status_code == 401
    assert response.json()["type"].endswith("/invalid-token")


def test_a_token_from_another_issuer_is_refused(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers=auth(issuer="https://evil.example")
    )
    assert response.status_code == 401


def test_an_unsigned_token_is_refused(client: TestClient) -> None:
    """`alg: none`, the oldest JWT bug there is."""
    unsigned = jwt.encode(
        {"sub": ALICE, "aud": AUDIENCE, "iss": ISSUER, "exp": int(time.time()) + 60},
        key="",
        algorithm="none",
    )
    response = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers={"Authorization": f"Bearer {unsigned}"}
    )
    assert response.status_code == 401


def test_a_token_with_no_expiry_is_refused(client: TestClient) -> None:
    claims = {"sub": ALICE, "aud": AUDIENCE, "iss": ISSUER}
    forever = jwt.encode(claims, JWT_SECRET, algorithm="HS256")
    response = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers={"Authorization": f"Bearer {forever}"}
    )
    assert response.status_code == 401
    assert response.json()["type"].endswith("/invalid-token")


def test_a_token_with_an_empty_subject_is_refused(client: TestClient) -> None:
    """An empty `sub` would scope every query to the same falsy account."""
    response = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth("   "))
    assert response.status_code == 401
    assert response.json()["detail"] == "The access token names no subject."


def test_garbage_in_the_authorization_header_is_refused(client: TestClient) -> None:
    for header in ("", "Bearer", "Bearer    ", "Basic abc", f"Token {token()}", "not-a-header"):
        response = client.post(
            "/v1/sync/pull", json={"cursor": None}, headers={"Authorization": header}
        )
        assert response.status_code == 401, header


def test_the_problem_body_never_contains_the_token(client: TestClient) -> None:
    presented = token(expires_in=-60)
    response = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers={"Authorization": f"Bearer {presented}"}
    )
    assert presented not in response.text
    assert ALICE not in response.text
