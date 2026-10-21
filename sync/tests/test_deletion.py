"""Deletion happens elsewhere, and reaches every device through the pull.

This service has no delete route. A programme's sync data is deleted with its
enrolment ("delete now", through the API; the foreign keys cascade) and an
account's with the account (also through the API). What this service owes the
person's other devices is to tell them:

* every pull lists the caller's current programmes (`current_areas`), and a
  client drops any local area missing from it, with its unpushed changes;
* a push to an area that no longer exists is `409 area_gone`, and the client
  discards that area's pending changes;
* once the account is gone, the token no longer authenticates, and the client
  signs out and wipes its local copy.
"""

from __future__ import annotations

import uuid
from collections.abc import Callable

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, delete, func, select

from thsync.schema import enrolments, sync_answer, sync_area, sync_lapse
from conftest import ALICE, auth, bundle


def _delete_enrolment(engine: Engine, enrolment_id: uuid.UUID) -> None:
    """What the API's "delete now" does to the row this service hangs off."""
    with engine.begin() as connection:
        connection.execute(delete(enrolments).where(enrolments.c.id == enrolment_id))


@pytest.mark.parametrize(
    ("method", "path"),
    [
        ("DELETE", "/v1/sync/account"),
        ("DELETE", "/v1/sync/areas/bf"),
        ("POST", "/v1/sync/delete"),
    ],
)
def test_there_is_no_delete_route(client: TestClient, method: str, path: str) -> None:
    response = client.request(method, path, headers=auth())
    assert response.status_code in (404, 405)
    assert response.headers["content-type"].startswith("application/problem+json")


def test_no_route_deletes(client: TestClient) -> None:
    methods = {
        method
        for route in client.app.routes  # type: ignore[attr-defined]
        for method in getattr(route, "methods", set())
    }
    assert "DELETE" not in methods


def test_a_deleted_enrolment_disappears_from_the_next_pull(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    bf = enrol(ALICE, "bf")
    enrol(ALICE, "nu")
    client.post("/v1/sync/push", json={"areas": [bundle("bf"), bundle("nu")]}, headers=auth())
    synced = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()
    assert synced["current_areas"] == ["bf", "nu"]

    _delete_enrolment(engine, bf)

    # From the old cursor nothing changed, but the list says bf is gone.
    later = client.post("/v1/sync/pull", json={"cursor": synced["cursor"]}, headers=auth()).json()
    assert later["areas"] == []
    assert later["current_areas"] == ["nu"]

    # Hard, at the row level: the cascade removed the area, its answers and
    # its lapses, and nothing of nu.
    with engine.connect() as connection:
        areas = connection.execute(select(sync_area.c.programme_code)).scalars().all()
        answers = connection.execute(select(func.count()).select_from(sync_answer)).scalar_one()
        lapses = connection.execute(select(func.count()).select_from(sync_lapse)).scalar_one()
    assert areas == ["nu"]
    assert answers == 1
    assert lapses == 1


def test_a_push_to_a_deleted_area_is_area_gone(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    bf = enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    _delete_enrolment(engine, bf)

    stale = client.post(
        "/v1/sync/push", json={"areas": [bundle("bf", base_revision=1)]}, headers=auth()
    )
    assert stale.status_code == 409
    assert stale.json()["type"].endswith("/area_gone")
    assert stale.json()["positions"] == [0]


def test_rejoining_does_not_resurrect_changes_made_before_the_deletion(
    client: TestClient, engine: Engine, enrol: Callable[..., uuid.UUID]
) -> None:
    """The member deleted the programme, then joined it again.

    A device still holding revision 1 of the old area must not file its
    pending changes under the new enrolment: that is the record the member
    deleted. Its push is `area_gone`; a fresh push (no base revision) starts
    the new area at revision 1.
    """
    old = enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [bundle("bf")]}, headers=auth())
    _delete_enrolment(engine, old)
    new = enrol(ALICE, "bf")

    stale = client.post(
        "/v1/sync/push", json={"areas": [bundle("bf", base_revision=1)]}, headers=auth()
    )
    assert stale.status_code == 409
    assert stale.json()["type"].endswith("/area_gone")

    fresh = client.post(
        "/v1/sync/push", json={"areas": [bundle("bf", lapses=[])]}, headers=auth()
    )
    assert fresh.json()["applied"] == ["bf"]
    with engine.connect() as connection:
        row = connection.execute(select(sync_area.c.enrolment_id, sync_area.c.revision)).one()
    assert (row.enrolment_id, row.revision) == (new, 1)
