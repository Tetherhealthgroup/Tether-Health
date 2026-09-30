"""Conflict detection: per area, reported, never merged."""

from __future__ import annotations

from fastapi.testclient import TestClient

from conftest import auth, bundle


def test_a_stale_revision_is_a_conflict_not_an_overwrite(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=1, status="paused")]},
        headers=auth(),
    )

    # A second device that last saw revision 1 and has been offline since.
    stale = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle(
                    "tobacco",
                    base_revision=1,
                    status="ended",
                    answers={"tobacco/S01": {"text": {"0": "from the stale device"}}},
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
    assert conflict["area"] == "tobacco"
    assert conflict["reason"] == "stale-revision"
    assert conflict["base_revision"] == 1
    assert conflict["server_revision"] == 2
    # The server's copy rides along so the client can resolve without a second
    # round trip — and so the decision is made where the person is.
    assert conflict["server"]["revision"] == 2
    assert conflict["server"]["enrolment"]["status"] == "paused"

    # Nothing was overwritten.
    current = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert current["enrolment"]["status"] == "paused"
    assert current["revision"] == 2


def test_claiming_a_revision_the_server_has_never_held_is_a_conflict(
    client: TestClient,
) -> None:
    """The client thinks it has synced this programme; the server has nothing.

    This is what a device sees after the programme was revoked and the account
    erased underneath it. Treating it as a create would resurrect a record the
    person deleted.
    """
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=4)]},
        headers=auth(),
    )
    conflict = response.json()["conflicts"][0]
    assert conflict["reason"] == "unknown-to-server"
    assert conflict["server_revision"] is None
    assert conflict["server"] is None
    assert response.json()["applied"] == []


def test_a_create_that_collides_with_an_existing_area_is_a_conflict(
    client: TestClient,
) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=None, status="ended")]},
        headers=auth(),
    )
    conflict = response.json()["conflicts"][0]
    assert conflict["reason"] == "stale-revision"
    assert conflict["base_revision"] is None
    assert conflict["server_revision"] == 1


def test_one_conflicted_programme_does_not_block_another(client: TestClient) -> None:
    """The segregation rule applied to conflicts.

    All-or-nothing would let one contested programme hold every other
    programme's sync hostage indefinitely.
    """
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())

    response = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle("tobacco", base_revision=99),
                bundle("nutrition", base_revision=None),
            ]
        },
        headers=auth(),
    )
    body = response.json()
    assert body["applied"] == ["nutrition"]
    assert [conflict["area"] for conflict in body["conflicts"]] == ["tobacco"]

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert sorted(area["area"] for area in pulled["areas"]) == ["nutrition", "tobacco"]


def test_a_conflict_does_not_advance_the_cursor_for_that_area(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    before = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["cursor"]

    client.post(
        "/v1/sync/push", json={"areas": [bundle("tobacco", base_revision=99)]}, headers=auth()
    )

    after = client.post("/v1/sync/pull", json={"cursor": before}, headers=auth()).json()
    assert after["areas"] == []
    assert after["cursor"] == before


def test_resolving_a_conflict_by_pushing_the_server_s_revision_succeeds(
    client: TestClient,
) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    conflict = client.post(
        "/v1/sync/push", json={"areas": [bundle("tobacco", base_revision=99)]}, headers=auth()
    ).json()["conflicts"][0]

    resolved = client.post(
        "/v1/sync/push",
        json={
            "areas": [
                bundle("tobacco", base_revision=conflict["server_revision"], status="ended")
            ]
        },
        headers=auth(),
    )
    assert resolved.json()["applied"] == ["tobacco"]
    current = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert current["enrolment"]["status"] == "ended"
    assert current["revision"] == 2


def test_the_same_programme_twice_in_one_push_is_refused(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("tobacco")]},
        headers=auth(),
    )
    assert response.status_code == 422
