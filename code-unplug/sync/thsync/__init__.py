"""Tether Health sync service.

One FastAPI application that syncs a person's `TetherSession` between their
devices, one programme at a time.

The shape of everything here follows from a single rule in 42 CFR Part 2: a
substance-use programme's record is segregated, and consent to disclose one
programme is not consent to disclose another. So the unit this service moves,
versions, conflicts, and deletes is an *area bundle* — one programme's
enrolment plus the answers and lapses that belong to it — and never the
session document as a whole. See `thsync.wire` for the bundle, and
`thsync.repository` for the conflict and revocation rules that fall out of it.
"""

__all__ = ["__version__"]

__version__ = "0.1.0"
