"""The request and response bodies, and the validation that guards them.

Two naming conventions live in this file and that is on purpose.

* Anything that came out of the client's stored document — `enrolment`,
  `sharing`, an answer block, a lapse — keeps the document's own camelCase
  names (`joinedOn`, `totalsAndAdherence`). These objects are copied from
  `TetherSession.toJson()` and written back into it verbatim. Renaming them
  here would make this file a second, independent definition of the session
  schema that somebody has to keep in step with
  `lib/tether/state/tether_session.dart`, and the first time the two drifted
  the symptom would be a person's sharing preference quietly reverting.
* Anything this service invented — `base_cursor`, `base_revision`, `revoked` —
  is snake_case, matching the endpoint contract.

`extra="forbid"` everywhere. The friendly alternative — ignore unknown fields —
means a client that starts sending a new answer block gets a 200 back for a
write that silently dropped it. For a health record, being told "no" is the
better failure.
"""

from __future__ import annotations

import re
from datetime import datetime, timezone
from typing import Annotated, Any, Final, Literal

from pydantic import (
    AwareDatetime,
    BaseModel,
    ConfigDict,
    Field,
    field_serializer,
    field_validator,
    model_validator,
)

from thsync import problems

__all__ = [
    "AreaBundle",
    "Conflict",
    "Enrolment",
    "Lapse",
    "PullRequest",
    "PullResponse",
    "PushRequest",
    "PushResponse",
    "RevokeResponse",
    "ScreenAnswers",
    "Sharing",
    "AREA_ID_PATTERN",
    "split_answer_key",
]

#: An area id as the client writes it. The `/` exclusion is load-bearing rather
#: than cosmetic: answers are attributed to a programme by the prefix of
#: `areaId/screenId`, so an area id containing a separator would make that
#: attribution ambiguous, which is the one thing the key format exists to
#: prevent.
AREA_ID_PATTERN: Final = re.compile(r"^[a-z0-9][a-z0-9_.-]{0,63}$")

#: Screen ids in the shell look like `S05`, `SH1`, `tobacco.cessation.3`.
#: Deliberately permissive on case, deliberately strict on `/`.
SCREEN_ID_PATTERN: Final = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$")

#: Ceiling on one push. Not a performance guard — a push is a phone's whole
#: record for one programme and is kilobytes — but a bound on what a single
#: transaction can be asked to hold.
MAX_AREAS_PER_PUSH: Final = 64

MAX_TEXT_LENGTH: Final = 8_192
MAX_BLOCKS_PER_SCREEN: Final = 256
MAX_SCREENS_PER_AREA: Final = 512
MAX_LAPSES_PER_AREA: Final = 5_000


class _Body(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)


def split_answer_key(key: str) -> tuple[str, str]:
    """Splits `areaId/screenId`, or raises `ValueError`.

    Mirrors `TetherSession.restoreFrom`, which drops a key with no `/` rather
    than filing it under a likely-looking programme — with one difference. The
    client *drops* the answer because the alternative there is refusing to open
    the app. The server *rejects the whole request*, because the alternative
    here is returning 200 for a write that lost data, and the phone that sent
    it has the only other copy.

    Splits on the first separator: a screen id may not contain `/`, so
    `a/b/c` is not a nested path, it is an invalid screen id, and saying so is
    better than silently accepting `b/c` as a screen.
    """
    area, separator, screen = key.partition("/")
    if not separator:
        raise ValueError(
            "an answer key must be 'areaId/screenId'; a key naming no "
            "programme cannot be attributed to one and will not be guessed at"
        )
    if not AREA_ID_PATTERN.match(area):
        raise ValueError("the area part of an answer key is not a valid area id")
    if not SCREEN_ID_PATTERN.match(screen):
        raise ValueError("the screen part of an answer key is not a valid screen id")
    return area, screen


def _block_map(value: dict[str, Any]) -> dict[str, Any]:
    """Checks a `{"blockIndex": …}` map.

    Block indices are ints in Dart and object keys in JSON, so they arrive as
    strings; `TetherSession._readBlocks` parses them back and skips what it
    cannot. Reject here instead of skipping, for the same reason as
    [split_answer_key], and require the canonical rendering of the integer so
    that `"0"` and `"00"` cannot become two rows for one block.
    """
    if len(value) > MAX_BLOCKS_PER_SCREEN:
        raise ValueError(f"a screen may carry at most {MAX_BLOCKS_PER_SCREEN} blocks")
    for key in value:
        try:
            index = int(key)
        except ValueError as error:
            raise ValueError("a block index must be an integer written as a string") from error
        if index < 0 or str(index) != key:
            raise ValueError("a block index must be a non-negative integer in canonical form")
    return value


class Sharing(_Body):
    """One programme's disclosure settings, as the client stores them."""

    totals_and_adherence: bool = Field(default=False, alias="totalsAndAdherence")
    notes: bool = False
    recipient: str | None = Field(default=None, max_length=256)


class Enrolment(_Body):
    """One programme's enrolment record."""

    #: The four `EnrolmentStatus` values. A `Literal` rather than a free string
    #: because the client maps an unrecognised status to `none`, and a status
    #: this service invented would silently un-enrol somebody on the next pull.
    status: Literal["none", "active", "paused", "ended"]
    hidden: bool = False
    joined_on: AwareDatetime | None = Field(default=None, alias="joinedOn")
    sharing: Sharing = Field(default_factory=Sharing)

    @field_serializer("joined_on")
    def _serialise_joined_on(self, value: datetime | None) -> str | None:
        return _iso_utc(value)


class ScreenAnswers(_Body):
    """What a person gave on one screen.

    Four maps rather than one tagged union, because that is what
    `TetherSession._encodeAnswers` writes and this is a transport.
    """

    chips: dict[str, list[int]] = Field(default_factory=dict)
    option: dict[str, int] = Field(default_factory=dict)
    slider: dict[str, float] = Field(default_factory=dict)
    text: dict[str, Annotated[str, Field(max_length=MAX_TEXT_LENGTH)]] = Field(
        default_factory=dict
    )

    @field_validator("chips", "option", "slider", "text")
    @classmethod
    def _check_block_indices(cls, value: dict[str, Any]) -> dict[str, Any]:
        return _block_map(value)

    @property
    def is_empty(self) -> bool:
        return not (self.chips or self.option or self.slider or self.text)


class Lapse(_Body):
    """One recorded lapse.

    `context` is free-form and comes from the person. It is stored and returned
    and never logged, the same as answer text.
    """

    at: AwareDatetime
    severity: str = Field(default="", max_length=64)
    context: list[Annotated[str, Field(max_length=256)]] = Field(default_factory=list)

    @field_serializer("at")
    def _serialise_at(self, value: datetime) -> str:
        return _iso_utc(value) or ""


class AreaBundle(_Body):
    """One programme's segregated record: the unit of sync.

    This is what a pull returns, what a push sends, and what a revocation
    destroys. Nothing in the API moves a smaller piece and nothing moves a
    larger one.

    `answers` is keyed by the full `areaId/screenId` — not by the bare screen
    id, which would be shorter and is what `TetherSession.exportRecord` does
    for a human reader. Keeping the full key means the client sends the keys
    from its own document untouched, so the attribution check happens *here*,
    on the exact string the client filed the answer under, rather than on a
    reconstruction of it. A bundle that has smuggled `nutrition/S02` into the
    `tobacco` bundle is a cross-programme merge, and it is caught by comparing
    two strings instead of being invisible.
    """

    area: str = Field(pattern=AREA_ID_PATTERN.pattern)

    #: Set by the server on the way out. On a push it is ignored in favour of
    #: [base_revision] — a client that could choose its own next revision could
    #: overwrite a conflict by claiming a high number.
    revision: int = 0

    #: The revision the client last saw for this area, or None if it believes
    #: the server has never held it. Mismatch is the conflict; see
    #: `thsync.repository.push_bundles`.
    #:
    #: `exclude` keeps it out of responses: it is a statement the *client*
    #: makes about its own state, and echoing it back in a pull would invite a
    #: client to read it as the server's answer to the same question, which is
    #: `revision`.
    base_revision: int | None = Field(default=None, exclude=True)

    #: True on a bundle describing a programme whose data has been destroyed.
    #: A pull returns these so that the other device learns to delete its copy.
    #: A push carrying `revoked: true` is refused — revocation goes through
    #: `DELETE /v1/sync/areas/{area_id}` so that it is one deliberate,
    #: attributable act rather than a side effect of a routine write.
    revoked: bool = False

    enrolment: Enrolment | None = None
    answers: dict[str, ScreenAnswers] = Field(default_factory=dict)
    lapses: list[Lapse] = Field(default_factory=list)

    @model_validator(mode="after")
    def _check_attribution(self) -> AreaBundle:
        if len(self.answers) > MAX_SCREENS_PER_AREA:
            raise ValueError(f"a bundle may carry at most {MAX_SCREENS_PER_AREA} screens")
        if len(self.lapses) > MAX_LAPSES_PER_AREA:
            raise ValueError(f"a bundle may carry at most {MAX_LAPSES_PER_AREA} lapses")
        for key in self.answers:
            area, _ = split_answer_key(key)
            if area != self.area:
                # The whole point of the module. An answer filed under another
                # programme must not ride along inside this one, whether that
                # is a client bug or a deliberate attempt to move a record
                # across a consent boundary.
                raise ValueError(
                    "an answer key names a different programme than the bundle "
                    "it arrived in; answers are not moved between programmes"
                )
        return self

    def screen_answers(self) -> dict[str, ScreenAnswers]:
        """The answers keyed by bare screen id, for storage.

        Safe only because [_check_attribution] has already proved every key
        belongs to `self.area`.
        """
        return {key.split("/", 1)[1]: value for key, value in self.answers.items()}


class PushBundle(AreaBundle):
    """An [AreaBundle] as a push may send it."""

    @model_validator(mode="after")
    def _check_push_shape(self) -> PushBundle:
        if self.revoked:
            raise ValueError(
                "a push may not revoke a programme; use DELETE /v1/sync/areas/{area_id}"
            )
        if self.enrolment is None:
            # Without an enrolment there is no programme, only orphaned
            # answers — and an answer with no enrolment behind it has no
            # consent record attached to it either.
            raise ValueError("a bundle must carry an enrolment")
        if self.base_revision is not None and self.base_revision < 0:
            raise ValueError("base_revision may not be negative")
        return self


class PullRequest(_Body):
    cursor: int | None = Field(default=None, ge=0)

    #: Optional filter. Present so a client can sync one programme without
    #: pulling the others — which is the Part 2 shape of a partial sync and not
    #: merely an optimisation. See `thsync.repository.pull_since` for what it
    #: does to the returned cursor.
    areas: list[Annotated[str, Field(pattern=AREA_ID_PATTERN.pattern)]] | None = None

    @field_validator("areas")
    @classmethod
    def _check_areas(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None
        if not value:
            raise ValueError("an empty area filter would select nothing; omit the field instead")
        if len(set(value)) != len(value):
            raise ValueError("the area filter repeats an area")
        return value


class PullResponse(_Body):
    cursor: int
    areas: list[AreaBundle]
    server_time: datetime

    @field_serializer("server_time")
    def _serialise_server_time(self, value: datetime) -> str:
        return _iso_utc(value) or ""


class PushRequest(_Body):
    base_cursor: int | None = Field(default=None, ge=0)
    areas: list[PushBundle] = Field(min_length=1, max_length=MAX_AREAS_PER_PUSH)

    @field_validator("areas")
    @classmethod
    def _check_unique(cls, value: list[PushBundle]) -> list[PushBundle]:
        names = [bundle.area for bundle in value]
        if len(set(names)) != len(names):
            # Two bundles for one programme in one push have no defined order
            # and no way to tell which the client meant to win.
            raise ValueError("a push names the same programme twice")
        return value


class Conflict(_Body):
    """One area the push did not apply, and why.

    `server` carries the server's current bundle so the client can resolve
    without a second round trip — and so that resolution is a decision made on
    the phone, where the person is, rather than by a merge rule on a server
    that cannot ask them anything.
    """

    area: str
    reason: Literal["stale-revision", "unknown-to-server"]
    base_revision: int | None
    server_revision: int | None
    server: AreaBundle | None


class PushResponse(_Body):
    cursor: int
    applied: list[str]
    conflicts: list[Conflict]
    server_time: datetime

    @field_serializer("server_time")
    def _serialise_server_time(self, value: datetime) -> str:
        return _iso_utc(value) or ""


class RevokeResponse(_Body):
    area: str
    revision: int
    cursor: int
    server_time: datetime

    @field_serializer("server_time")
    def _serialise_server_time(self, value: datetime) -> str:
        return _iso_utc(value) or ""


def _iso_utc(value: datetime | None) -> str | None:
    """Renders an instant the way the Dart client writes one.

    `datetime.isoformat()` produces `+00:00`; `DateTime.toIso8601String()` on a
    UTC instant produces `Z`. Both parse on both sides, so this is not a
    correctness fix — it means a document that round-trips through the server
    comes back byte-identical, and `SessionStore` skips the rewrite instead of
    treating every sync as a change.
    """
    if value is None:
        return None
    moment = value.astimezone(timezone.utc)
    return moment.isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _collect_field_names() -> set[str]:
    """Every field name and alias this module declares.

    Feeds `problems.KNOWN_FIELD_NAMES`, which uses it to decide what in a
    validation error location is a field of ours (safe to name) and what is a
    value the caller chose (redacted). Derived rather than hand-listed so that
    a new field cannot be born redacted and confusing.
    """
    names: set[str] = set()
    for model in (
        Sharing,
        Enrolment,
        ScreenAnswers,
        Lapse,
        AreaBundle,
        PushBundle,
        PullRequest,
        PullResponse,
        PushRequest,
        Conflict,
        PushResponse,
        RevokeResponse,
    ):
        for name, field in model.model_fields.items():
            names.add(name)
            if field.alias:
                names.add(field.alias)
    return names


problems.KNOWN_FIELD_NAMES |= _collect_field_names()
