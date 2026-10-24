"""Push then pull, and the cursor arithmetic that connects them."""

from __future__ import annotations

from typing import Any

from fastapi.testclient import TestClient

from conftest import auth, bundle


def test_health_needs_no_token(client: TestClient) -> None:
    response = client.get("/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_push_then_pull_returns_the_same_document(client: TestClient) -> None:
    sent = bundle("tobacco")
    pushed = client.post("/v1/sync/push", json={"base_cursor": None, "areas": [sent]}, headers=auth())
    assert pushed.status_code == 200, pushed.text
    assert pushed.json()["applied"] == ["tobacco"]
    assert pushed.json()["conflicts"] == []

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth())
    assert pulled.status_code == 200, pulled.text
    body = pulled.json()
    assert len(body["areas"]) == 1

    got = body["areas"][0]
    assert got["area"] == "tobacco"
    assert got["revision"] == 1
    assert got["revoked"] is False
    assert got["enrolment"] == sent["enrolment"]
    # The key comes back in the full `areaId/screenId` form the client files it
    # under, so the client can write it straight back into its document.
    assert got["answers"] == sent["answers"]
    assert got["lapses"] == sent["lapses"]


def test_a_pulled_bundle_does_not_echo_the_client_s_base_revision(
    client: TestClient,
) -> None:
    """`revision` is the server's answer; `base_revision` is the question."""
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    got = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert "base_revision" not in got
    assert got["revision"] == 1


def test_pull_at_the_returned_cursor_returns_nothing(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())
    first = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()

    second = client.post("/v1/sync/pull", json={"cursor": first["cursor"]}, headers=auth())
    assert second.json()["areas"] == []
    assert second.json()["cursor"] == first["cursor"]


def test_second_push_supersedes_the_first(client: TestClient) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth())

    updated = bundle(
        "tobacco",
        base_revision=1,
        status="paused",
        answers={"tobacco/S07": {"text": {"0": "later answer"}}},
        lapses=[],
    )
    response = client.post("/v1/sync/push", json={"areas": [updated]}, headers=auth())
    assert response.json()["applied"] == ["tobacco"]

    got = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert got["revision"] == 2
    assert got["enrolment"]["status"] == "paused"
    # Whole-bundle replacement: the screen from the first push is gone, not
    # merged into the second.
    assert list(got["answers"]) == ["tobacco/S07"]
    assert got["lapses"] == []


def test_filtered_pull_does_not_advance_past_what_it_withheld(client: TestClient) -> None:
    """The cursor rule from `repository.pull_since`, end to end.

    Two programmes change; the client asks for one. If the returned cursor ran
    ahead of the change it did not send, the other programme would never be
    pulled again — a permanently missing record with no error anywhere.
    """
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("nutrition")]},
        headers=auth(),
    )

    filtered = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["tobacco"]}, headers=auth()
    ).json()
    assert [area["area"] for area in filtered["areas"]] == ["tobacco"]

    # Resuming from that cursor without a filter must still find nutrition.
    rest = client.post("/v1/sync/pull", json={"cursor": filtered["cursor"]}, headers=auth()).json()
    assert "nutrition" in [area["area"] for area in rest["areas"]]


def test_cursor_from_the_future_is_refused(client: TestClient) -> None:
    response = client.post("/v1/sync/pull", json={"cursor": 999}, headers=auth())
    assert response.status_code == 409
    assert response.headers["content-type"].startswith("application/problem+json")
    body: dict[str, Any] = response.json()
    assert body["type"].endswith("/unknown-cursor")
    assert body["status"] == 409
    assert body["cursor"] == 0


def test_push_base_cursor_from_the_future_is_refused(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/push", json={"base_cursor": 7, "areas": [bundle()]}, headers=auth()
    )
    assert response.status_code == 409
    # And nothing was written.
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"] == []


def test_every_area_of_the_real_programme_list_round_trips(client: TestClient) -> None:
    """All eleven programmes, to prove nothing is special-cased by name."""
    areas = [
        "tobacco",
        "metabolic",
        "cancer",
        "cardiovascular",
        "nutrition",
        "respiratory",
        "kidney_liver",
        "behavioral",
        "preventive",
        "aging",
        "digital",
    ]
    response = client.post(
        "/v1/sync/push", json={"areas": [bundle(area) for area in areas]}, headers=auth()
    )
    assert response.status_code == 200, response.text
    assert sorted(response.json()["applied"]) == sorted(areas)

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert sorted(area["area"] for area in pulled["areas"]) == sorted(areas)
    # One change number per area write, not one per request.
    assert pulled["cursor"] == len(areas)
