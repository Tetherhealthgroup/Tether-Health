"""Malformed input, unattributable answers, and what an error body may say."""

from __future__ import annotations

import httpx
import pytest
from fastapi.testclient import TestClient

from thsync.wire import split_answer_key
from conftest import auth, bundle


def _push(client: TestClient, area_bundle: dict[str, object]) -> httpx.Response:
    # Annotated on the way through: starlette's TestClient is typed as
    # returning Any under the httpx shim it currently ships with.
    response: httpx.Response = client.post(
        "/v1/sync/push", json={"areas": [area_bundle]}, headers=auth()
    )
    return response


def test_an_answer_key_with_no_separator_is_refused(client: TestClient) -> None:
    """The rule from `TetherSession.restoreFrom`, enforced harder.

    The client drops such a key because the alternative is refusing to open the
    app. The server rejects the request, because the alternative here is
    answering 200 to a write that lost data.
    """
    response = _push(client, bundle("tobacco", answers={"S05": {"text": {"0": "x"}}}))
    assert response.status_code == 422
    assert response.json()["type"].endswith("/invalid-request")
    # Nothing was written: the whole request is refused, not the one key.
    assert client.post("/v1/sync/pull", json={"cursor": None}, headers=auth()).json()["areas"] == []


def test_an_answer_key_naming_another_programme_is_refused(client: TestClient) -> None:
    """The cross-programme merge this service exists to prevent."""
    response = _push(
        client, bundle("tobacco", answers={"nutrition/S05": {"text": {"0": "x"}}})
    )
    assert response.status_code == 422


def test_an_answer_key_with_an_empty_area_is_refused(client: TestClient) -> None:
    assert _push(client, bundle("tobacco", answers={"/S05": {}})).status_code == 422


def test_an_answer_key_with_an_empty_screen_is_refused(client: TestClient) -> None:
    assert _push(client, bundle("tobacco", answers={"tobacco/": {}})).status_code == 422


def test_a_nested_looking_answer_key_is_refused(client: TestClient) -> None:
    """`a/b/c` is not a path; it is a screen id containing a separator."""
    assert _push(client, bundle("tobacco", answers={"tobacco/a/b": {}})).status_code == 422


@pytest.mark.parametrize("key", ["S05", "/S05", "tobacco/", "tobacco/a/b", ""])
def test_split_answer_key_refuses_what_it_cannot_attribute(key: str) -> None:
    with pytest.raises(ValueError):
        split_answer_key(key)


def test_split_answer_key_accepts_the_client_s_format() -> None:
    assert split_answer_key("tobacco/S05") == ("tobacco", "S05")
    assert split_answer_key("kidney_liver/SH1") == ("kidney_liver", "SH1")


def test_a_non_integer_block_index_is_refused(client: TestClient) -> None:
    """Block indices are ints in Dart and strings in JSON.

    `TetherSession._readBlocks` skips one it cannot parse; here it is a 422,
    for the same reason as an unattributable key.
    """
    response = _push(client, bundle("tobacco", answers={"tobacco/S05": {"text": {"x": "y"}}}))
    assert response.status_code == 422


def test_a_non_canonical_block_index_is_refused(client: TestClient) -> None:
    """`"0"` and `"00"` would otherwise become two rows for one block."""
    response = _push(client, bundle("tobacco", answers={"tobacco/S05": {"option": {"00": 1}}}))
    assert response.status_code == 422


def test_an_unknown_enrolment_status_is_refused(client: TestClient) -> None:
    """The client maps an unknown status to `none`, i.e. not enrolled.

    Accepting one here would silently un-enrol somebody on their next pull.
    """
    assert _push(client, bundle("tobacco", status="graduated")).status_code == 422


def test_an_unknown_field_is_refused_rather_than_dropped(client: TestClient) -> None:
    sent = bundle("tobacco")
    sent["streak"] = 12
    assert _push(client, sent).status_code == 422


def test_a_bundle_with_no_enrolment_is_refused(client: TestClient) -> None:
    sent = bundle("tobacco")
    sent["enrolment"] = None
    assert _push(client, sent).status_code == 422


def test_an_area_id_containing_a_separator_is_refused(client: TestClient) -> None:
    """An area id with a `/` would make answer-key attribution ambiguous."""
    assert _push(client, bundle("tobacco/extra")).status_code == 422


def test_a_naive_timestamp_is_refused(client: TestClient) -> None:
    """An instant with no offset is ambiguous, and lapse times are clinical."""
    sent = bundle("tobacco", lapses=[{"at": "2026-09-15T07:00:00", "severity": "minor"}])
    assert _push(client, sent).status_code == 422


def test_an_empty_area_filter_is_refused(client: TestClient) -> None:
    response = client.post("/v1/sync/pull", json={"cursor": None, "areas": []}, headers=auth())
    assert response.status_code == 422


def test_a_push_with_no_bundles_is_refused(client: TestClient) -> None:
    assert client.post("/v1/sync/push", json={"areas": []}, headers=auth()).status_code == 422


def test_a_validation_problem_never_echoes_what_the_person_wrote(
    client: TestClient,
) -> None:
    """The rule from `thsync.problems`: positions and codes, never content.

    An error body is the response most likely to be captured verbatim by a log
    or a crash reporter, so it must not carry the free text, the lapse context,
    or the programme name.
    """
    secret_text = "i relapsed on tuesday"
    sent = bundle(
        "tobacco",
        answers={"tobacco/S05": {"text": {"not-an-index": secret_text}}},
        lapses=[
            {
                "at": "2026-09-15T07:00:00.000Z",
                "severity": "major",
                "context": ["argument with my brother"],
            }
        ],
    )
    response = _push(client, sent)
    assert response.status_code == 422

    body = response.text
    assert secret_text not in body
    assert "brother" not in body
    assert "tobacco" not in body
    assert "not-an-index" not in body

    # What it does carry: a count, the rule, and a redacted position.
    problem = response.json()
    assert problem["status"] == 422
    assert problem["errors"]
    assert problem["errors"][0]["at"].startswith("body.areas.0")


def test_a_problem_body_is_always_rfc7807(client: TestClient) -> None:
    for response in (
        client.post("/v1/sync/pull", json={"cursor": -1}, headers=auth()),
        client.post("/v1/sync/pull", json={"cursor": 5}, headers=auth()),
        client.delete("/v1/sync/areas/tobacco", headers=auth()),
        client.get("/v1/nothing-here", headers=auth()),
    ):
        assert response.headers["content-type"].startswith("application/problem+json")
        body = response.json()
        assert set(body) >= {"type", "title", "status", "detail"}
        assert body["status"] == response.status_code
        assert body["type"].startswith("https://tetherhealthgroup.com/problems/")
