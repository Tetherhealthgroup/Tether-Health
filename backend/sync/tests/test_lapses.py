"""Lapses are append-only, and a conflict never loses one.

A push repeats every stored lapse unchanged at its position and may add new
ones after them. Changing or dropping a stored lapse, or adding one whose
ordinal was taken meanwhile, refuses the whole push with `409 lapse_conflict`
and writes nothing. The client then pulls, renumbers its unpushed lapses after
the server's last one, drops any whose content the server already holds, and
pushes again.
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, event, func, select

from thsync import repository
from thsync.schema import sync_lapse
from conftest import ALICE, auth, bundle

FIRST = {"at": "2026-09-15T07:00:00.000Z", "severity": "minor", "context": ["stress"]}
FROM_PHONE = {"at": "2026-09-16T08:00:00.000Z", "severity": "major", "context": ["party"]}
FROM_TABLET = {"at": "2026-09-16T21:15:00.000Z", "severity": "minor", "context": []}


def _push(client: TestClient, *bundles: dict[str, Any]) -> Any:
    return client.post("/v1/sync/push", json={"areas": list(bundles)}, headers=auth())


def _pull(client: TestClient) -> dict[str, Any]:
    body: dict[str, Any] = client.post(
        "/v1/sync/pull", json={"cursor": None}, headers=auth()
    ).json()
    return body


def _lapse_rows(engine: Engine) -> int:
    with engine.connect() as connection:
        return int(connection.execute(select(func.count()).select_from(sync_lapse)).scalar_one())


@pytest.fixture
def seeded(client: TestClient, enrol: Callable[..., uuid.UUID]) -> TestClient:
    enrol(ALICE, "bf", "sf")
    assert _push(client, bundle("bf", lapses=[FIRST])).json()["applied"] == ["bf"]
    return client


def test_changing_a_stored_lapse_is_refused_and_nothing_is_written(
    seeded: TestClient, engine: Engine
) -> None:
    edited = {**FIRST, "severity": "major"}
    response = _push(
        seeded,
        # A valid bundle first, to prove the refusal rolls back the whole push.
        bundle("sf", lapses=[FROM_PHONE]),
        bundle("bf", base_revision=1, lapses=[edited]),
    )
    assert response.status_code == 409
    assert response.headers["content-type"].startswith("application/problem+json")
    problem = response.json()
    assert problem["type"].endswith("/lapse_conflict")
    # Positions, never the programme or the lapse content.
    assert problem["positions"] == [1]
    assert '"bf"' not in response.text and "major" not in response.text

    pulled = _pull(seeded)
    assert [area["area"] for area in pulled["areas"]] == ["bf"]
    assert pulled["areas"][0]["lapses"] == [FIRST]
    assert pulled["areas"][0]["revision"] == 1
    assert _lapse_rows(engine) == 1


def test_dropping_a_stored_lapse_is_refused(seeded: TestClient) -> None:
    response = _push(seeded, bundle("bf", base_revision=1, lapses=[]))
    assert response.status_code == 409
    assert response.json()["type"].endswith("/lapse_conflict")
    assert _pull(seeded)["areas"][0]["lapses"] == [FIRST]


def test_reordering_stored_lapses_is_refused(seeded: TestClient) -> None:
    _push(seeded, bundle("bf", base_revision=1, lapses=[FIRST, FROM_PHONE]))
    response = _push(seeded, bundle("bf", base_revision=2, lapses=[FROM_PHONE, FIRST]))
    assert response.status_code == 409


def test_a_new_lapse_colliding_with_one_stored_meanwhile_is_refused(
    seeded: TestClient, engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """The store's own unique key (`23505`) is the last line.

    Simulated by hiding the stored lapse from the service's read, as a
    concurrent write it had not seen would be: the insert then collides on the
    primary key, and the push is refused rather than failing with a 500.
    """
    real = repository._stored_lapses

    def stale_read(*args: Any) -> list[Any]:
        return real(*args)[:-1]

    monkeypatch.setattr(repository, "_stored_lapses", stale_read)
    response = _push(seeded, bundle("bf", base_revision=1, lapses=[FROM_PHONE]))
    monkeypatch.undo()

    assert response.status_code == 409, response.text
    assert response.json()["type"].endswith("/lapse_conflict")
    assert response.json()["positions"] == [0]
    # The stored lapse is untouched and nothing new was written.
    assert _pull(seeded)["areas"][0]["lapses"] == [FIRST]
    assert _lapse_rows(engine) == 1


def test_two_devices_picking_the_same_ordinal_lose_no_lapse(seeded: TestClient) -> None:
    """Both devices last saw revision 1 with one lapse; each records another
    offline, at ordinal 1.

    The phone pushes first. The tablet's push conflicts; it follows the client
    rule (pull, renumber after the server's last lapse, drop any the server
    already holds) and pushes again. Both lapses survive, in order.
    """
    phone = _push(seeded, bundle("bf", base_revision=1, lapses=[FIRST, FROM_PHONE]))
    assert phone.json()["applied"] == ["bf"]

    tablet = _push(seeded, bundle("bf", base_revision=1, lapses=[FIRST, FROM_TABLET]))
    conflict = tablet.json()["conflicts"][0]
    assert conflict["reason"] == "stale-revision"

    server_lapses = conflict["server"]["lapses"]
    unpushed = [FROM_TABLET, FROM_PHONE]  # The tablet also holds a copy of the phone's.
    renumbered = server_lapses + [lapse for lapse in unpushed if lapse not in server_lapses]
    retry = _push(
        seeded,
        bundle("bf", base_revision=conflict["server_revision"], lapses=renumbered),
    )
    assert retry.json()["applied"] == ["bf"], retry.text

    assert _pull(seeded)["areas"][0]["lapses"] == [FIRST, FROM_PHONE, FROM_TABLET]


def test_the_service_never_updates_a_lapse_or_deletes_anything(
    seeded: TestClient, engine: Engine
) -> None:
    """Lapse rows are insert-only, and no sync row is ever deleted here.

    On PostgreSQL the grants and the append-only trigger enforce this; the
    statement log proves the service does not even try.
    """
    statements: list[str] = []

    def record(_conn: Any, clause: Any, *_: Any) -> None:
        statements.append(str(clause).upper())

    event.listen(engine, "before_execute", record)
    try:
        _push(seeded, bundle("bf", base_revision=1, answers={}, lapses=[FIRST, FROM_PHONE]))
        _push(seeded, bundle("bf", base_revision=2, answers={}, lapses=[FIRST]))
        _push(seeded, bundle("sf", answers={"sf/plan": {"option": {"0": 1}}}, lapses=[]))
    finally:
        event.remove(engine, "before_execute", record)

    assert statements
    assert not [s for s in statements if s.lstrip().startswith("DELETE")]
    assert not [s for s in statements if s.lstrip().startswith("UPDATE SYNC_LAPSE")]
