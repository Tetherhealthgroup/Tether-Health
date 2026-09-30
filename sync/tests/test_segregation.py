"""42 CFR Part 2 segregation: one programme in, one programme out, one gone.

These are the tests the design exists for. If any of them fails, the service is
syncing a session document with programme-shaped labels on it rather than
segregated programme records, and it should not be deployed.
"""

from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import Engine, func, select

from thsync.schema import sync_answer, sync_area, sync_lapse
from conftest import ALICE, auth, bundle


def _push_three(client: TestClient) -> None:
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco"), bundle("nutrition"), bundle("aging")]},
        headers=auth(),
    )
    assert response.status_code == 200, response.text


def test_a_pull_can_name_one_programme_and_get_only_that_one(client: TestClient) -> None:
    _push_three(client)
    body = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["nutrition"]}, headers=auth()
    ).json()
    assert [area["area"] for area in body["areas"]] == ["nutrition"]
    assert all("tobacco" not in key for key in body["areas"][0]["answers"])


def test_writing_one_programme_does_not_touch_the_others(client: TestClient) -> None:
    _push_three(client)
    before = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    revisions = {area["area"]: area["revision"] for area in before["areas"]}

    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=revisions["tobacco"])]},
        headers=auth(),
    )

    after = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    now = {area["area"]: area["revision"] for area in after["areas"]}
    assert now["tobacco"] == revisions["tobacco"] + 1
    # The point: nothing else moved. A whole-document design would have
    # re-versioned these two as a side effect of the tobacco write.
    assert now["nutrition"] == revisions["nutrition"]
    assert now["aging"] == revisions["aging"]

    # And only the written programme shows up as changed.
    delta = client.post("/v1/sync/pull", json={"cursor": before["cursor"]}, headers=auth()).json()
    assert [area["area"] for area in delta["areas"]] == ["tobacco"]


def test_revoking_one_programme_leaves_the_others_intact(
    client: TestClient, engine: Engine
) -> None:
    _push_three(client)

    revoked = client.delete("/v1/sync/areas/tobacco", headers=auth())
    assert revoked.status_code == 200, revoked.text
    assert revoked.json()["area"] == "tobacco"
    assert revoked.json()["revision"] == 2

    body = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    byarea = {area["area"]: area for area in body["areas"]}

    # The tombstone: enough for the other device to delete its copy, and
    # nothing else.
    assert byarea["tobacco"]["revoked"] is True
    assert byarea["tobacco"]["enrolment"] is None
    assert byarea["tobacco"]["answers"] == {}
    assert byarea["tobacco"]["lapses"] == []

    assert byarea["nutrition"]["revoked"] is False
    assert byarea["nutrition"]["enrolment"]["status"] == "active"
    assert byarea["nutrition"]["answers"] != {}
    assert byarea["aging"]["answers"] != {}

    # Hard, at the row level — not a flag with the rows still there.
    with engine.connect() as connection:
        answers = connection.execute(
            select(func.count())
            .select_from(sync_answer)
            .where(sync_answer.c.account_id == ALICE, sync_answer.c.area_id == "tobacco")
        ).scalar_one()
        lapses = connection.execute(
            select(func.count())
            .select_from(sync_lapse)
            .where(sync_lapse.c.account_id == ALICE, sync_lapse.c.area_id == "tobacco")
        ).scalar_one()
        survivors = connection.execute(
            select(func.count())
            .select_from(sync_answer)
            .where(sync_answer.c.account_id == ALICE)
        ).scalar_one()
    assert answers == 0
    assert lapses == 0
    assert survivors == 2  # nutrition and aging, untouched


def test_revocation_is_visible_as_a_change_to_a_client_at_the_old_cursor(
    client: TestClient,
) -> None:
    _push_three(client)
    synced = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()

    client.delete("/v1/sync/areas/tobacco", headers=auth())

    delta = client.post("/v1/sync/pull", json={"cursor": synced["cursor"]}, headers=auth()).json()
    assert [area["area"] for area in delta["areas"]] == ["tobacco"]
    assert delta["areas"][0]["revoked"] is True


def test_revoking_twice_is_not_an_error_and_spends_no_revision(client: TestClient) -> None:
    _push_three(client)
    first = client.delete("/v1/sync/areas/tobacco", headers=auth()).json()
    second = client.delete("/v1/sync/areas/tobacco", headers=auth())
    assert second.status_code == 200
    assert second.json()["revision"] == first["revision"]


def test_revoking_a_programme_the_account_never_had_is_a_404(client: TestClient) -> None:
    _push_three(client)
    response = client.delete("/v1/sync/areas/respiratory", headers=auth())
    assert response.status_code == 404
    assert response.headers["content-type"].startswith("application/problem+json")
    assert response.json()["type"].endswith("/unknown-area")


def test_a_revoked_programme_can_be_joined_again(client: TestClient) -> None:
    """Revocation is not a permanent ban; the person may enrol a second time.

    The revision keeps climbing rather than restarting, so a device holding the
    tombstone can tell the new record from the old one.
    """
    _push_three(client)
    tombstone = client.delete("/v1/sync/areas/tobacco", headers=auth()).json()

    rejoined = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("tobacco", base_revision=tombstone["revision"])]},
        headers=auth(),
    )
    assert rejoined.json()["applied"] == ["tobacco"]

    got = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["tobacco"]}, headers=auth()
    ).json()["areas"][0]
    assert got["revoked"] is False
    assert got["revision"] == tombstone["revision"] + 1


def test_revocation_only_touches_the_caller_s_own_copy(client: TestClient) -> None:
    """Two accounts enrolled in the same programme; one revokes."""
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth("alice-1"))
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth("bob-2"))

    client.delete("/v1/sync/areas/tobacco", headers=auth("alice-1"))

    bobs = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth("bob-2")).json()
    assert bobs["areas"][0]["revoked"] is False
    assert bobs["areas"][0]["answers"] != {}


def test_a_push_may_not_revoke(client: TestClient) -> None:
    """Revocation goes through DELETE so that it is one deliberate act."""
    sneaky = bundle("tobacco")
    sneaky["revoked"] = True
    response = client.post("/v1/sync/push", json={"areas": [sneaky]}, headers=auth())
    assert response.status_code == 422


def test_area_rows_are_never_shared_between_accounts(client: TestClient, engine: Engine) -> None:
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth("alice-1"))
    client.post("/v1/sync/push", json={"areas": [bundle("tobacco")]}, headers=auth("bob-2"))
    with engine.connect() as connection:
        rows = connection.execute(
            select(sync_area.c.account_id, sync_area.c.area_id, sync_area.c.revision)
        ).all()
    assert sorted((row.account_id, row.area_id, row.revision) for row in rows) == [
        ("alice-1", "tobacco", 1),
        ("bob-2", "tobacco", 1),
    ]
