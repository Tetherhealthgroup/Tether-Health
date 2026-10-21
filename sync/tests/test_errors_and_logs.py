"""What leaves the process when things go wrong, and what goes into the log.

Two of the quality rules in this service are negative — "never leak internals"
and "never log PHI" — and a negative rule with no test is a comment.
"""

from __future__ import annotations

import logging
import uuid
from collections.abc import Callable
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import insert
from sqlalchemy.engine import Connection

from thsync import repository
from thsync.schema import sync_answer
from thsync.wire import PushBundle
from conftest import ALICE, auth, bundle

SECRET_TEXT = "i smoked three on the way home"
SECRET_CONTEXT = "row with my landlord"


def _revealing_bundle(area: str = "bf") -> dict[str, Any]:
    return bundle(
        area,
        answers={f"{area}/S05": {"text": {"0": SECRET_TEXT}, "slider": {"1": 73.5}}},
        lapses=[
            {
                "at": "2026-09-15T07:00:00.000Z",
                "severity": "major",
                "context": [SECRET_CONTEXT],
            }
        ],
    )


def test_an_unexpected_failure_returns_a_problem_with_no_internals(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    def explode(*_: object, **__: object) -> None:
        raise RuntimeError("relation \"sync_area\" does not exist on host db-3")

    monkeypatch.setattr(repository, "pull_since", explode)

    response = client.post("/v1/sync/pull", json={"cursor": None}, headers=auth())
    assert response.status_code == 500
    assert response.headers["content-type"].startswith("application/problem+json")
    body = response.json()
    assert body["type"].endswith("/internal-error")
    assert body["detail"] == "The request could not be completed. Nothing was changed."
    # No driver message, no table name, no host.
    assert "sync_area" not in response.text
    assert "db-3" not in response.text
    assert "Traceback" not in response.text


def test_a_successful_sync_logs_counts_and_never_content(
    client: TestClient, caplog: pytest.LogCaptureFixture, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    with caplog.at_level(logging.DEBUG, logger="thsync"):
        client.post("/v1/sync/push", json={"areas": [_revealing_bundle()]}, headers=auth())
        client.post("/v1/sync/pull", json={"cursor": None}, headers=auth())

    written = caplog.text
    assert written, "the sync operations logged nothing at all"

    for forbidden in (SECRET_TEXT, SECRET_CONTEXT, "73.5", "major", "2026-09-15T07:00"):
        assert forbidden not in written

    # What it may contain: the account and counts.
    assert ALICE in written
    assert "applied=1" in written
    assert "current=1" in written


def test_a_refused_push_logs_the_reason_and_no_content(
    client: TestClient, caplog: pytest.LogCaptureFixture, enrol: Callable[..., uuid.UUID]
) -> None:
    enrol(ALICE, "bf")
    client.post("/v1/sync/push", json={"areas": [_revealing_bundle()]}, headers=auth())
    changed = _revealing_bundle()
    changed["base_revision"] = 1
    changed["lapses"][0]["severity"] = "minor"

    with caplog.at_level(logging.DEBUG, logger="thsync"):
        lapse = client.post("/v1/sync/push", json={"areas": [changed]}, headers=auth())
        gone = client.post(
            "/v1/sync/push", json={"areas": [_revealing_bundle("ca")]}, headers=auth()
        )
    assert lapse.status_code == 409
    assert gone.status_code == 409

    written = caplog.text
    assert "LapseConflict" in written
    assert "AreaGone" in written
    for forbidden in (SECRET_TEXT, SECRET_CONTEXT, "73.5", "major", "2026-09-15T07:00"):
        assert forbidden not in written
        assert forbidden not in lapse.text
        assert forbidden not in gone.text


def test_a_database_error_logs_no_bound_parameters(
    client: TestClient,
    caplog: pytest.LogCaptureFixture,
    monkeypatch: pytest.MonkeyPatch,
    enrol: Callable[..., uuid.UUID],
) -> None:
    """A constraint violation's traceback must not carry the answer text.

    The engine hides bound parameters (`hide_parameters=True`); without that,
    the statement error in the log would include the payload.
    """
    enrol(ALICE, "bf")

    def insert_twice(connection: Connection, user_id: uuid.UUID, pushed: PushBundle) -> None:
        row = {
            "user_id": user_id,
            "programme_code": pushed.area,
            "screen_id": "S05",
            "payload": {"text": {"0": SECRET_TEXT}},
        }
        connection.execute(insert(sync_answer), [row])
        connection.execute(insert(sync_answer), [row])

    monkeypatch.setattr(repository, "_write_answers", insert_twice)
    with caplog.at_level(logging.DEBUG, logger="thsync"):
        response = client.post(
            "/v1/sync/push", json={"areas": [_revealing_bundle()]}, headers=auth()
        )
    assert response.status_code == 500
    assert "IntegrityError" in caplog.text
    assert SECRET_TEXT not in caplog.text
    assert SECRET_TEXT not in response.text


def test_a_rejected_request_logs_a_count_and_not_the_body(
    client: TestClient, caplog: pytest.LogCaptureFixture
) -> None:
    broken = _revealing_bundle()
    broken["answers"]["bf/S05"]["option"] = {"invented": 1}

    with caplog.at_level(logging.DEBUG, logger="thsync"):
        assert (
            client.post("/v1/sync/push", json={"areas": [broken]}, headers=auth()).status_code
            == 422
        )

    written = "\n".join(record.getMessage() for record in caplog.records)
    assert "validation error" in written
    assert SECRET_TEXT not in written
    assert "invented" not in written


def test_a_failed_authentication_logs_no_token(
    client: TestClient, caplog: pytest.LogCaptureFixture
) -> None:
    with caplog.at_level(logging.DEBUG, logger="thsync"):
        response = client.post(
            "/v1/sync/pull", json={"cursor": None}, headers=auth(expires_in=-60)
        )
    assert response.status_code == 401

    written = "\n".join(record.getMessage() for record in caplog.records)
    assert "expired-token" in written
    assert "eyJ" not in written  # the leading bytes of every JWT header
