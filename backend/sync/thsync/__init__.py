"""Tether Health sync service.

One FastAPI application that syncs a person's programme answers and lapses
between their devices, one programme at a time.

The shape of everything here follows from a single rule in 42 CFR Part 2: a
substance-use programme's record is segregated, and consent to disclose one
programme is not consent to disclose another. So the unit this service moves,
versions and conflicts on is an *area bundle* — one programme's answers and
lapses — and never the person's data as a whole. Enrolment and consent belong
to the API; this service reads them and never stores a copy. See `thsync.wire`
for the bundle, and `thsync.repository` for the conflict rules.
"""

__all__ = ["__version__"]

__version__ = "0.1.0"
