"""Full erasure, the server side of `TetherSession.deleteEverything`.

The client's contract is that deletion is "completed rather than hidden", and
`SH4`'s copy commits to it clearing the phone, the servers, and anything queued
to sync. These tests are what makes the "the servers" part of that sentence
true rather than aspirational.
"""

from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import Engine, func, select

from thsync.schema import sync_account, sync_answer, sync_area, sync_lapse
from conftest import ALICE, BOB, auth, bundle


def _row_counts(engine: Engine) -> dict[str, int]:
    with engine.connect() as connection:
        return {
            table.name: connection.execute(select(func.count()).select_from(table)).scalar_one()
            for table in (sync_account, sync_area, sync_answer, sync_lapse)
        }


def test_erasure_removes_every_row_for_the_account(client: TestClient, engine: Engine) -> None:
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("nutrition"), bundle("aging")]},
        headers=auth(ALICE),
    )
    assert _row_counts(engine)["sync_answer"] == 3

    response = client.delete("/v1/sync/account", headers=auth(ALICE))
    assert response.status_code == 204
    assert response.content == b""

    assert _row_counts(engine) == {
        "sync_account": 0,
        "sync_area": 0,
        "sync_answer": 0,
        "sync_lapse": 0,
    }


def test_erasure_takes_the_tombstones_too(client: TestClient, engine: Engine) -> None:
    """A revoked programme leaves a tombstone; a full erasure leaves nothing.

    This is why erasure cannot be built out of repeated single-area
    revocations: after eleven revocations there would still be eleven rows
    saying which programmes this person had been in.
    """
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("nutrition")]},
        headers=auth(ALICE),
    )
    client.delete("/v1/sync/areas/tobacco", headers=auth(ALICE))
    assert _row_counts(engine)["sync_area"] == 2

    client.delete("/v1/sync/account", headers=auth(ALICE))
    assert _row_counts(engine)["sync_area"] == 0


def test_after_erasure_a_pull_looks_like_a_phone_that_never_synced(
    client: TestClient,
) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))
    client.delete("/v1/sync/account", headers=auth(ALICE))

    body = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth(ALICE)).json()
    assert body["areas"] == []
    assert body["cursor"] == 0


def test_erasure_is_idempotent(client: TestClient) -> None:
    """The client calls this having already told the person their data is gone.

    A 404 on the retry after a dropped connection would contradict that.
    """
    assert client.delete("/v1/sync/account", headers=auth(ALICE)).status_code == 204
    assert client.delete("/v1/sync/account", headers=auth(ALICE)).status_code == 204


def test_a_device_that_pushes_after_erasure_does_not_resurrect_the_record(
    client: TestClient,
) -> None:
    """The second phone has not heard, and pushes what it still holds.

    It must be told it is out of date rather than silently recreating a record
    the person deleted — the resolution belongs on the device, which knows it
    has just been erased.
    """
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))
    client.delete("/v1/sync/account", headers=auth(ALICE))

    stale = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=1)]},
        headers=auth(ALICE),
    ).json()
    assert stale["applied"] == []
    assert stale["conflicts"][0]["reason"] == "unknown-to-server"


def test_erasure_does_not_reach_another_account(client: TestClient, engine: Engine) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(ALICE))
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth(BOB))

    client.delete("/v1/sync/account", headers=auth(ALICE))

    counts = _row_counts(engine)
    assert counts["sync_area"] == 1
    assert counts["sync_answer"] == 1
    with engine.connect() as connection:
        survivor = connection.execute(select(sync_area.c.account_id)).scalar_one()
    assert survivor == BOB
