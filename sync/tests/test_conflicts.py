"""Conflict detection: per area, reported, never merged."""

from __future__ import annotations

import uuid
from collections.abc import Callable

from fastapi.testclient import TestClient

from conftest import ALICE, auth, bundle


def test_a_stale_revision_is_a_conflict_not_an_overwrite(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle("bf", base_revision=1, answers={"bf/S05": {"text": {"0": "second"}}})
            ]
        },
        headers=auth(),
    )

    # A second device that last saw revision 1 and has been offline since.
    stale = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle(
                    "bf",
                    base_revision=1,
                    answers={"bf/S01": {"text": {"0": "from the stale device"}}},
                )
            ]
        },
        headers=auth(),
    )
    assert stale.status_code == 200
    body = stale.json()
    assert body["applied"] == []
    assert len(body["conflicts"]) == 1

    conflict = body["conflicts"][0]
    assert conflict["area"] == "bf"
    assert conflict["reason"] == "stale-revision"
    assert conflict["base_revision"] == 1
    assert conflict["server_revision"] == 2
    # The server's copy rides along so the client can resolve without a second
    # round trip — and so the decision is made where the person is.
    assert conflict["server"]["revision"] == 2
    assert conflict["server"]["answers"]["bf/S05"]["text"] == {"0": "second"}

    # Nothing was overwritten.
    current = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert "bf/S01" not in current["answers"]
    assert current["revision"] == 2


def test_a_create_that_collides_with_an_existing_area_is_a_conflict(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf", base_revision=None)]},
        headers=auth(),
    )
    conflict = response.json()["conflicts"][0]
    assert conflict["reason"] == "stale-revision"
    assert conflict["base_revision"] is None
    assert conflict["server_revision"] == 1


def test_one_conflicted_programme_does_not_block_another(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """The segregation rule applied to conflicts.

    All-or-nothing would let one contested programme hold every other
    programme's sync hostage indefinitely.
    """
    enrol(ALICE, "bf", "nu")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())

    response = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle("bf", base_revision=99),
                bundle("nu", base_revision=None),
            ]
        },
        headers=auth(),
    )
    body = response.json()
    assert body["applied"] == ["nu"]
    assert [conflict["area"] for conflict in body["conflicts"]] == ["bf"]

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert sorted(area["area"] for area in pulled["areas"]) == ["bf", "nu"]


def test_a_conflict_does_not_advance_the_cursor_for_that_area(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    before = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["cursor"]

    client.post("/v1/sync/push", json={"areas": [bundle("bf", base_revision=99)]}, headers=auth())

    after = client.post("/v1/sync/pull", json={"cursor": before}, headers=auth()).json()
    assert after["areas"] == []
    assert after["cursor"] == before


def test_resolving_a_conflict_by_pushing_the_server_s_revision_succeeds(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    conflict = client.post(
        "/v1/sync/push", json={"areas": [bundle("bf", base_revision=99)]}, headers=auth()
    ).json()["conflicts"][0]

    resolved = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle(
                    "bf",
                    base_revision=conflict["server_revision"],
                    answers={"bf/S05": {"option": {"0": 2}}},
                )
            ]
        },
        headers=auth(),
    )
    assert resolved.json()["applied"] == ["bf"]
    current = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert current["answers"]["bf/S05"]["option"] == {"0": 2}
    assert current["revision"] == 2


def test_the_same_programme_twice_in_one_push_is_refused(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("bf")]},
        headers=auth(),
    )
    assert response.status_code == 422
