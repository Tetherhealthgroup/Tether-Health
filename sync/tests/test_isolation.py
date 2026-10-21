"""Cross-account isolation.

The account id is taken from the verified `sub` and never from the request
body, so these tests are about proving that the queries actually use it — a
missing `WHERE user_id = …` is the one bug in this service that discloses one
person's treatment record to another. On PostgreSQL row-level security checks
the same thing a second time (`test_postgres.py`).
"""

from __future__ import annotations

import uuid
from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, select

from thsync.schema import sync_area
from conftest import ALICE, BOB, auth, bundle


def test_one_account_cannot_read_another_s_bundles(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf", "nu")
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("nu")]},
        headers=auth(ALICE),
    )

    bobs = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(BOB))
    assert bobs.status_code == 200
    assert bobs.json()["areas"] == []
    assert bobs.json()["cursor"] == 0
    # Not even which programmes Alice is in.
    assert bobs.json()["current_areas"] == []


def test_a_named_area_filter_does_not_reach_another_account(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth(ALICE))
    bobs = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["bf"]}, headers=auth(BOB)
    )
    assert bobs.json()["areas"] == []


def test_another_account_s_enrolment_does_not_let_a_push_through(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """Bob is not enrolled in bf; Alice is. Bob's push for bf is refused."""
    enrol(ALICE, "bf")
    response = client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth(BOB))
    assert response.status_code == 409
    assert response.json()["type"].endswith("/area_gone")


def test_another_account_s_cursor_is_meaningless_here(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """Alice's cursor presented on Bob's token.

    Refused rather than quietly clamped to zero: a cursor from a history this
    account does not have means the client's state and the token disagree, and
    resynchronising is the only safe answer.
    """
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth(ALICE))
    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()

    bobs = client.post("/v1/sync/pull", json={"cursor": alice["cursor"]}, headers=auth(BOB))
    assert bobs.status_code == 409


def test_two_accounts_keep_independent_cursors(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf", "sd")
    enrol(BOB, "bf")
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("sd")]},
        headers=auth(ALICE),
    )
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth(BOB))

    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    bobs = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(BOB)).json()

    # Per-account counters: Bob's first write is 1 even though Alice wrote
    # twice first. A global sequence would leak the service's write rate into
    # every client's cursor.
    assert alice["cursor"] == 2
    assert bobs["cursor"] == 1


def test_two_accounts_in_the_same_programme_keep_separate_rows(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    alice_bf = enrol(ALICE, "bf")
    bob_bf = enrol(BOB, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth(ALICE))
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf", answers={"bf/S05": {"text": {"0": "bob's"}}})]},
        headers=auth(BOB),
    )
    with engine.connect() as connection:
        rows = connection.execute(
            select(sync_area.c.user_id, sync_area.c.enrolment_id, sync_area.c.revision)
        ).all()
    # Each area hangs off its own owner's enrolment.
    assert sorted((str(row.user_id), row.enrolment_id, row.revision) for row in rows) == sorted(
        [(ALICE, alice_bf, 1), (BOB, bob_bf, 1)]
    )

    alice = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    assert alice["areas"][0]["answers"]["bf/S05"]["text"] == {"3": "free text"}


def test_a_push_cannot_name_the_account_it_writes_to(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """There is no account field on the wire, and adding one is rejected."""
    enrol(ALICE, "bf")
    body = {"areas": [bundle("bf")], "user_id": BOB}
    assert client.post("/v1/sync/push", json=body, headers=auth(ALICE)).status_code == 422
