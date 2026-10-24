"""42 CFR Part 2 segregation: one programme in, one programme out.

These are the tests the design exists for. If any of them fails, the service is
syncing a person's whole record with programme-shaped labels on it rather than
segregated programme records, and it should not be deployed.
"""

from __future__ import annotations

import uuid
from collections.abc import Callable

from fastapi.testclient import TestClient
from sqlalchemy import Engine, func, select

from thsync.schema import sync_answer, sync_area
from conftest import ALICE, auth, bundle, set_status


def _push_three(client: TestClient, enrol: Callable[..., uuid.UUID]) -> None:
    enrol(ALICE, "bf", "nu", "sd")
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("nu"), bundle("sd")]},
        headers=auth(),
    )
    assert response.status_code == 200, response.text


def test_a_pull_can_name_one_programme_and_get_only_that_one(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    _push_three(client, enrol)
    body = client.post(
        "/v1/sync/pull", json={"cursor": None, "areas": ["nu"]}, headers=auth()
    ).json()
    assert [area["area"] for area in body["areas"]] == ["nu"]
    assert all(key.startswith("nu/") for key in body["areas"][0]["answers"])


def test_writing_one_programme_does_not_touch_the_others(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    _push_three(client, enrol)
    before = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    revisions = {area["area"]: area["revision"] for area in before["areas"]}

    client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf", base_revision=revisions["bf"])]},
        headers=auth(),
    )

    after = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    now = {area["area"]: area["revision"] for area in after["areas"]}
    assert now["bf"] == revisions["bf"] + 1
    # The point: nothing else moved. A whole-document design would have
    # re-versioned these two as a side effect of the bf write.
    assert now["nu"] == revisions["nu"]
    assert now["sd"] == revisions["sd"]

    # And only the written programme shows up as changed.
    delta = client.post("/v1/sync/pull", json={"cursor": before["cursor"]}, headers=auth()).json()
    assert [area["area"] for area in delta["areas"]] == ["bf"]


def test_an_answer_cannot_be_filed_under_another_programme(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf", "sf")
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf", answers={"sf/plan": {"option": {"0": 1}}})]},
        headers=auth(),
    )
    assert response.status_code == 422
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"] == []


def test_a_push_for_a_programme_with_no_enrolment_is_rejected(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    """No enrolment, no consent record: nothing to file the data under.

    Refused as a whole, even though the other programme in the push is
    enrolled, and nothing at all is written.
    """
    enrol(ALICE, "bf")
    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf"), bundle("ca")]},
        headers=auth(),
    )
    assert response.status_code == 409
    problem = response.json()
    assert problem["type"].endswith("/area_gone")
    assert problem["positions"] == [1]
    # The programme is not named, only its position.
    assert '"ca"' not in response.text

    with engine.connect() as connection:
        assert connection.execute(select(func.count()).select_from(sync_area)).scalar_one() == 0
        assert connection.execute(select(func.count()).select_from(sync_answer)).scalar_one() == 0


def test_a_left_programme_is_read_only(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    """Leaving keeps the programme's data and stops new writes to it."""
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    set_status(engine, ALICE, "bf", "left")

    response = client.post(
        "/v1/sync/push",
        json={"areas": [bundle("bf", base_revision=1, answers={})]},
        headers=auth(),
    )
    assert response.status_code == 403
    assert response.json()["type"].endswith("/consent_required")
    assert response.json()["positions"] == [0]

    pulled = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert pulled["current_areas"] == ["bf"]
    assert pulled["areas"][0]["answers"] != {}
    assert pulled["areas"][0]["revision"] == 1


def test_each_area_hangs_off_the_enrolment_for_its_own_programme(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    bf = enrol(ALICE, "bf")
    nu = enrol(ALICE, "nu")
    client.post(
        "/v1/sync/push", json={"areas": [bundle("bf"), bundle("nu")]}, headers=auth()
    )
    with engine.connect() as connection:
        rows = {
            str(row.programme_code): row.enrolment_id
            for row in connection.execute(
                select(sync_area.c.programme_code, sync_area.c.enrolment_id)
            ).all()
        }
    assert rows == {"bf": bf, "nu": nu}


def test_a_push_may_not_carry_enrolment_or_sharing(
    client: TestClient, enrol: Callable[..., uuid.UUID]
) -> None:
    """Enrolment and consent belong to the API; sync is never a second copy."""
    enrol(ALICE, "bf")
    for field, value in (
        ("enrolment", {"status": "active"}),
        ("sharing", {"notes": True}),
        ("revoked", True),
    ):
        sent = bundle("bf")
        sent[field] = value
        response = client.post("/v1/sync/push", json={"areas": [sent]}, headers=auth())
        assert response.status_code == 422, field
