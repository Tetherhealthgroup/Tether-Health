"""The one logger this service uses, and the rule about what may go into it.

There is a single module-level logger rather than `getLogger(__name__)` per
module, because the interesting property of these logs is not which file wrote
a line — it is that *every* line came through one place that can be pointed at
during a Part 2 review.

**What may be logged:** account ids, programme (area) ids, counts, revisions,
cursors, status codes, exception types.

**What may never be logged:** answer text, slider values, chip selections,
lapse severity or context, `joinedOn`, sharing recipients, bearer tokens, JWT
claims, or any SQL with bound parameters. Those are the contents of a
substance-use treatment record; a log line is a disclosure with no consent
attached to it.

Area ids are on the permitted side after some thought. Knowing that an account
has a `tobacco` bundle does say the person is enrolled in a tobacco programme,
which is not nothing — but a sync service that cannot say which programme a
request touched cannot be debugged at all, and the alternative (hashing them)
produces logs that are unreadable to the person who needs them and still
correlatable to anybody with the id list. The line is drawn at content.
"""

from __future__ import annotations

import logging
from typing import Final

__all__ = ["log"]

log: Final = logging.getLogger("thsync")
