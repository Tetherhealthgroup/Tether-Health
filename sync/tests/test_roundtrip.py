"""Push then pull, and the cursor arithmetic that connects them."""

from __future__ import annotations

import uuid
from collections.abc import Callable
from typing import Any

from fastapi.testclient import TestClient
from sqlalchemy import Engine, select

from thsync.schema import sync_answer
from thsync.wire import PROGRAMME_CODES
from conftest import ALICE, auth, bundle

EMPTY_SCREEN: dict[str, dict[str, Any]] = {"chips": {}, "option": {}, "slider": {}, "text": {}}


def test_health_needs_no_token(client: TestClient) -> None:
    response = client.get("/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_push_then_pull_returns_the_same_document(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    sent = bundle("bf")
    pushed = client.post(
        "/v1/sync/push", json={"base_cursor": None, "areas": [sent]}, headers=auth()
    )
    assert pushed.status_code == 200, pushed.text
    assert pushed.json()["applied"] == ["bf"]
    assert pushed.json()["conflicts"] == []

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth())
    assert pulled.status_code == 200, pulled.text
    body = pulled.json()
    assert len(body["areas"]) == 1
    assert body["current_areas"] == ["bf"]

    got = body["areas"][0]
    assert set(got) == {"area", "revision", "answers", "lapses"}
    assert got["area"] == "bf"
    assert got["revision"] == 1
    # The key comes back in the full `programme/screenId` form the client
    # files it under, so the client can write it straight back.
    assert got["answers"] == sent["answers"]
    assert got["lapses"] == sent["lapses"]


def test_a_pulled_bundle_does_not_echo_the_client_s_base_revision(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """`revision` is the server's answer; `base_revision` is the question."""
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    got = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert "base_revision" not in got
    assert got["revision"] == 1


def test_pull_at_the_returned_cursor_returns_nothing(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    first = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()

    second = client.post("/v1/sync/pull", json={"cursor": first["cursor"]}, headers=auth())
    assert second.json()["areas"] == []
    assert second.json()["cursor"] == first["cursor"]
    # The current programmes are listed even when nothing changed.
    assert second.json()["current_areas"] == ["bf"]


def test_a_second_push_replaces_answers_and_appends_lapses(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    first = bundle("bf")
    client.post("/v1/sync/push", json={"areas": [first]}, headers=auth())

    later_lapse = {"at": "2026-09-16T08:30:00.000Z", "severity": "major", "context": []}
    updated = bundle(
        "bf",
        base_revision=1,
        answers={"bf/S07": {"text": {"0": "later answer"}}},
        lapses=[*first["lapses"], later_lapse],
    )
    response = client.post("/v1/sync/push", json={"areas": [updated]}, headers=auth())
    assert response.json()["applied"] == ["bf"], response.text

    got = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"][0]
    assert got["revision"] == 2
    # The screen the second push no longer carries is cleared, not merged:
    # its content is gone and it comes back empty.
    assert got["answers"]["bf/S05"] == EMPTY_SCREEN
    assert got["answers"]["bf/S07"]["text"] == {"0": "later answer"}
    # Lapses are appended, never replaced.
    assert got["lapses"] == [*first["lapses"], later_lapse]

    with engine.connect() as connection:
        stored = {
            str(row.screen_id): row.payload
            for row in connection.execute(
                select(sync_answer.c.screen_id, sync_answer.c.payload).where(
                    sync_answer.c.user_id == uuid.UUID(ALICE)
                )
            ).all()
        }
    # Stored as `{}` exactly: the old answer text is not kept anywhere.
    assert stored["S05"] == {}
    assert stored["S07"] == {"text": {"0": "later answer"}}


def test_an_explicitly_cleared_screen_is_stored_as_an_empty_object(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    cleared = bundle("bf", base_revision=1, answers={"bf/S05": {}})
    assert client.post("/v1/sync/push", json={"areas": [cleared]}, headers=auth()).json()[
        "applied"
    ] == ["bf"]
    with engine.connect() as connection:
        payload = connection.execute(select(sync_answer.c.payload)).scalar_one()
    assert payload == {}


def test_filtered_pull_does_not_advance_past_what_it_withheld(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """The cursor rule from `repository.pull_since`, end to end.

    Two programmes change; the client asks for one. If the returned cursor ran
    ahead of the change it did not send, the other programme would never be
    pulled again — a permanently missing record with no error anywhere.
    """
    enrol(ALICE, "bf", "nu")
    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("nu")]},
        headers=auth(),
    )

    filtered = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["bf"]}, headers=auth()
    ).json()
    assert [area["area"] for area in filtered["areas"]] == ["bf"]
    # The filter narrows the bundles, never the list of current programmes.
    assert filtered["current_areas"] == ["bf", "nu"]

    # Resuming from that cursor without a filter must still find nu.
    rest = client.post("/v1/sync/pull", json={"cursor": filtered["cursor"]}, headers=auth()).json()
    assert "nu" in [area["area"] for area in rest["areas"]]


def test_cursor_from_the_future_is_refused(client: TestClient) -> None:
    response = client.post("/v1/sync/pull", json={"cursor": 999}, headers=auth())
    assert response.status_code == 409
    assert response.headers["content-type"].startswith("application/problem+json")
    body: dict[str, Any] = response.json()
    assert body["type"].endswith("/unknown-cursor")
    assert body["status"] == 409
    assert body["cursor"] == 0


def test_push_base_cursor_from_the_future_is_refused(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    response = client.post(
        "/v1/sync/push", json={"base_cursor": 7, "areas": [bundle()]}, headers=auth()
    )
    assert response.status_code == 409
    # And nothing was written.
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"] == []


def test_every_programme_code_round_trips(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """All eleven programmes, to prove nothing is special-cased by name."""
    codes = sorted(PROGRAMME_CODES)
    assert len(codes) == 11
    enrol(ALICE, *codes)
    response = client.post(
        "/v1/sync/push", json={"areas": [bundle(code) for code in codes]}, headers=auth()
    )
    assert response.status_code == 200, response.text
    assert sorted(response.json()["applied"]) == codes

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert sorted(area["area"] for area in pulled["areas"]) == codes
    assert pulled["current_areas"] == codes
    # One change number per area write, not one per request.
    assert pulled["cursor"] == len(codes)


def test_a_commit_that_fails_is_never_reported_as_success(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    """The transaction commits before the response is sent.

    If it committed afterwards, a failed commit would leave the client holding
    a 200 for a push the database rolled back.
    """
    from sqlalchemy import event

    enrol(ALICE, "bf")

    def refuse_commit(_: Any) -> None:
        raise RuntimeError("commit failed")

    event.listen(engine, "commit", refuse_commit)
    try:
        response = client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    finally:
        event.remove(engine, "commit", refuse_commit)
    assert response.status_code == 500
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"] == []
