"""Cross-account isolation.

The account id is taken from the verified `sub` and never from the request
body, so these tests are about proving that the queries actually use it — a
missing `WHERE account_id = …` is the one bug in this service that discloses
one person's treatment record to another.
"""

from __future__ import annotations

from fastapi.testclient import TestClient

from conftest import ALICE, BOB, auth, bundle


def test_one_account_cannot_read_another_s_bundles(client: TestClient) -> None:
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("nutrition")]},
        headers=auth(ALICE),
    )

    bobs = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(BOB))
    assert bobs.status_code == 200
    assert bobs.json()["areas"] == []
    assert bobs.json()["cursor"] == 0


def test_a_named_area_filter_does_not_reach_another_account(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))
    bobs = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["tobacco"]}, headers=auth(BOB)
    )
    assert bobs.json()["areas"] == []


def test_another_account_s_cursor_is_meaningless_here(client: TestClient) -> None:
    """Alice's cursor presented on Bob's token.

    Refused rather than quietly clamped to zero: a cursor from a history this
    account does not have means the client's state and the token disagree, and
    resynchronising is the only safe answer.
    """
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))
    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()

    bobs = client.post("/v1/sync/pull", json={"cursor": alice["cursor"]}, headers=auth(BOB))
    assert bobs.status_code == 409


def test_one_account_cannot_revoke_another_s_programme(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))

    attempt = client.delete("/v1/sync/areas/tobacco", headers=auth(BOB))
    assert attempt.status_code == 404

    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    assert alice["areas"][0]["revoked"] is False
    assert alice["areas"][0]["answers"] != {}


def test_one_account_cannot_erase_another(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))

    assert client.delete("/v1/sync/account", headers=auth(BOB)).status_code == 204

    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    assert len(alice["areas"]) == 1


def test_two_accounts_keep_independent_cursors(client: TestClient) -> None:
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("aging")]},
        headers=auth(ALICE),
    )
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(BOB))

    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    bobs = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(BOB)).json()

    # Per-account counters: Bob's first write is 1 even though Alice wrote
    # twice first. A global sequence would leak the service's write rate into
    # every client's cursor.
    assert alice["cursor"] == 2
    assert bobs["cursor"] == 1


def test_a_push_cannot_name_the_account_it_writes_to(client: TestClient) -> None:
    """There is no account field on the wire, and adding one is rejected."""
    body = {"areas": [bundle("tobacco")], "account_id": BOB}
    assert client.post("/v1/sync/push", json=body, headers=auth(ALICE)).status_code == 422
