# Tether Health sync service

A FastAPI service that syncs a person's `TetherSession` between their devices,
**one programme at a time**.

The client (`lib/tether/state/tether_session.dart`) keeps one JSON document per
person, schema version 2. This service does *not* store that document. It
stores one segregated bundle per programme — the enrolment, its answers and its
lapses — because 42 CFR Part 2 treats each substance-use programme's record as
separately consented and separately revocable, and a whole-document design
cannot express "delete the tobacco programme and leave everything else alone".

Every design decision below is explained where it lives; the docstrings are the
documentation and this file is the map.

| I want to know… | Read |
| --- | --- |
| why the unit of sync is a programme, and the conflict policy | `thsync/repository.py` module docstring |
| the request/response shapes and their validation | `thsync/wire.py` |
| what may and may not go into a log | `thsync/logs.py` |
| why error bodies say so little | `thsync/problems.py` |
| why SQLAlchemy Core and not the ORM; what the tombstone is | `thsync/schema.py` |
| why the handlers are `def` and not `async def` | `thsync/db.py` |
| token verification | `thsync/auth.py` |

---

## Running it

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt            # add -r requirements-postgres.txt for the PG driver

export THSYNC_JWT_SECRET='<the Supabase JWT secret>'
export THSYNC_DATABASE_URL='postgresql+psycopg://user:pass@host/db'

uvicorn --factory thsync.app:create_app --port 8080
```

`create_app` is a factory, not a module-level `app`, so tests can hand it their
own engine. `--factory` is therefore required.

Against SQLite for local work, create the tables first — the `.sql` migrations
are Postgres DDL and will not run on SQLite:

```bash
export THSYNC_JWT_SECRET='local-dev-secret-at-least-32-bytes-long'
export THSYNC_DATABASE_URL='sqlite+pysqlite:///./thsync.db'
python -c 'from thsync.config import settings_from_env as s; from thsync.db import *; create_schema(create_engine_from_settings(s()))'
uvicorn --factory thsync.app:create_app --port 8080
```

### Tests

```bash
pip install -r requirements-dev.txt
pytest          # 84 tests, in-process, no network and no server
mypy            # strict
```

The suite runs against in-memory SQLite. There is no Postgres in it; see
[What is not verified](#what-is-not-verified).

### Migrations

Plain `.sql` in `migrations/`, named `YYYYMMDDHHmmss_name.sql`, applied by the
deployment runner in filename order. No `BEGIN`/`COMMIT` inside — the runner
wraps each file in its own transaction.

`tests/test_migration_matches_schema.py` compares the DDL against
`thsync/schema.py` (table names, column names, primary keys) so the two cannot
drift silently. It cannot compare types.

---

## Configuration

| Variable | Required | Default | Meaning |
| --- | --- | --- | --- |
| `THSYNC_JWT_SECRET` | **yes** | — | Supabase HS256 JWT secret. Start-up fails without it rather than accepting unverified tokens. |
| `THSYNC_DATABASE_URL` | no | `sqlite+pysqlite:///./thsync.db` | SQLAlchemy URL. Production: `postgresql+psycopg://…` |
| `THSYNC_JWT_AUDIENCE` | no | `authenticated` | Required `aud`. Supabase signs `anon` tokens with the same key, so this check is what keeps the public key out. |
| `THSYNC_JWT_ISSUER` | no | unset (not checked) | Required `iss` when set, e.g. `https://<project>.supabase.co/auth/v1`. |
| `THSYNC_JWT_LEEWAY_SECONDS` | no | `10` | Clock skew tolerated on `exp`/`iat`. |
| `THSYNC_SQL_ECHO` | no | `false` | Echo SQL. **Do not enable in production** — statement parameters include answer text. |

---

## API contract

Base path `/v1`. Everything except `/v1/health` needs
`Authorization: Bearer <supabase access token>`. The account is the verified
`sub`; there is no account id anywhere in a path, query or body, so there is no
code path that could forget to scope a query.

All errors are RFC 7807 `application/problem+json`:

```json
{ "type": "https://tetherhealthgroup.com/problems/unknown-cursor",
  "title": "Conflict", "status": 409, "detail": "…" }
```

### The area bundle

One programme's whole record. Field names inside `enrolment`, `answers` and
`lapses` are the client document's own, verbatim.

```json
{
  "area": "tobacco",
  "revision": 3,
  "base_revision": 2,
  "revoked": false,
  "enrolment": {
    "status": "active",
    "hidden": false,
    "joinedOn": "2026-09-15T07:00:00.000Z",
    "sharing": {"totalsAndAdherence": true, "notes": false, "recipient": null}
  },
  "answers": {
    "tobacco/S05": {"chips": {"0": [1, 2]}, "option": {"1": 3},
                    "slider": {"2": 90.0}, "text": {"3": "free text"}}
  },
  "lapses": [
    {"at": "2026-09-15T07:00:00.000Z", "severity": "minor", "context": ["stress"]}
  ]
}
```

* `revision` — server-assigned, monotonic **per area**. Read-only.
* `base_revision` — client-supplied on push only; the revision it last saw.
  Never echoed in a response.
* `revoked` — `true` on a tombstone. A push may not set it; use the DELETE.
* `answers` keys are `areaId/screenId` and the prefix **must** equal `area`. A
  key with no `/` is rejected, not guessed at, and neither is a key naming a
  different programme. Block indices are non-negative integers in canonical
  string form (`"0"`, not `"00"`).
* Timestamps must carry an offset. They are returned in UTC as `…Z`, matching
  Dart's `toIso8601String()` so a document round-trips byte-identically and
  `SessionStore` skips the rewrite.
* Unknown fields are rejected (422), not ignored.

### `GET /v1/health`

No auth, no database access. `200 {"status": "ok"}`.

### `POST /v1/sync/pull`

```json
{"cursor": 12, "areas": ["tobacco"]}
```

`cursor` is `null` for a first sync. `areas` is an optional filter.

```json
{"cursor": 17, "areas": [ …bundles… ], "server_time": "2026-09-15T15:06:50.257Z"}
```

Returns every bundle changed after `cursor`, including tombstones for
programmes that were revoked — that is how the other device learns to delete
its copy.

**Filtered pulls and the cursor.** When `areas` is given, the returned cursor
is the highest value below which *nothing was withheld*: one less than the
smallest change number that was filtered out, or the account's current counter
if nothing was. A client may therefore be handed the same bundle twice; it will
never be silently skipped past one. `409 unknown-cursor` if the cursor is ahead
of this account's history (a restored backup, or a token that now names a
different account) — pull from `null` to resynchronise.

### `POST /v1/sync/push`

```json
{"base_cursor": 12, "areas": [ …bundles with base_revision… ]}
```

```json
{"cursor": 19, "applied": ["nutrition"],
 "conflicts": [
   {"area": "tobacco", "reason": "stale-revision",
    "base_revision": 1, "server_revision": 2, "server": { …bundle… }}
 ],
 "server_time": "…"}
```

**Conflict policy: per-area optimistic concurrency, reported and never merged.**
If a bundle's `base_revision` does not equal the server's current revision for
that area, that bundle is not applied; the server's current bundle is returned
with it so the client can resolve in one round trip. The bundles that did match
are still applied — a conflict on one programme must not hold another
programme's sync hostage. `reason` is `stale-revision` when the server has the
area and `unknown-to-server` when the client claims a revision for an area the
server has never held (which is what a device sees after an erasure).

Last-writer-wins, at the document *or* the area level, is not used: a phone
that has been offline for a week would silently destroy a week of a clinical
record. Server-side field merge is not used either — two devices disagreeing
about an answer is a question only the person can be asked, and they are on
the phone, not here.

Always `200`, even when every bundle conflicted: the request succeeded and is
reporting per-area outcomes. Duplicated areas in one push are `422`.

A whole push is one transaction: it commits or rolls back entire.

### `DELETE /v1/sync/areas/{area_id}`

Revokes consent for one programme and hard-deletes its data. `200`:

```json
{"area": "tobacco", "revision": 4, "cursor": 21, "server_time": "…"}
```

The answers and lapses rows are **deleted**. What remains is the area row
carrying its id, the bumped revision and `revoked: true` — a tombstone, so the
person's other device learns on its next pull to delete its copy. No other
programme is read, rewritten or re-versioned. `404 unknown-area` if the account
has no such programme; revoking an already-revoked programme is `200` and spends
no revision. A revoked programme can be joined again, continuing the revision
sequence.

### `DELETE /v1/sync/account`

`204`, always, including when there was nothing to delete. Removes every row for
the account — areas, answers, lapses, tombstones and the account row itself.
Afterwards a pull is indistinguishable from one by a phone that has never
synced. This is the server half of `TetherSession.deleteEverything`, whose
contract is that deletion is "completed rather than hidden"; it cannot be built
out of repeated single-area revocations, because those leave eleven tombstones
naming eleven programmes.

---

## PHI handling

* **Logs carry ids and counts only.** Account ids, area ids, revisions,
  cursors, counts, error codes. Never answer text, slider values, chip
  selections, lapse severity or context, `joinedOn`, sharing recipients, tokens
  or claims. `thsync/logs.py` states the rule; `tests/test_errors_and_logs.py`
  enforces it.
* SQLAlchemy is constructed with `hide_parameters=True`, because otherwise a
  single constraint violation writes the bound parameters — i.e. someone's
  free-text answer — into the log via the traceback.
* **Error bodies carry positions and codes, never content.** A 422 will say
  that the third bundle failed and why the rule exists; it will not name the
  programme or repeat what was typed. An error body is the response most likely
  to be captured verbatim by an aggregator or a proxy.
* The interactive docs (`/docs`, `/redoc`) are disabled: they post real bodies
  from a browser. The OpenAPI document itself is still served.

## What is not verified

Stated plainly, because the tests cannot cover it here:

* **Nothing has been run against PostgreSQL.** There is no Postgres server and
  no Docker in the environment this was built in. The whole suite runs on
  SQLite. Specifically unverified: that `migrations/*.sql` applies cleanly,
  that `timestamptz` round-trips as the code assumes, that `jsonb` accepts what
  the JSON variant sends, and that the composite foreign keys behave as
  written. Apply the migration to a scratch database and re-run a manual round
  trip before the first deploy.
* `psycopg` (in `requirements-postgres.txt`) has never been installed here and
  is range-pinned rather than exact for that reason.
* Concurrency is reasoned about, not load-tested. `_next_seq` relies on the
  `UPDATE` taking a row lock so two simultaneous pushes for one account
  serialise; that is Postgres behaviour and is not exercised by a
  single-threaded SQLite suite.
* The `type` URI base (`https://tetherhealthgroup.com/problems/`) was chosen to
  match the repo's domain. The sibling Node service is not present in this
  repository, so it has **not** been checked against that service's actual
  base; change `PROBLEM_TYPE_BASE` in `thsync/problems.py` if it differs.
* No rate limiting, no request-size limit beyond the per-field bounds in
  `thsync/wire.py`, and no readiness probe. Those belong to whatever fronts
  this service, and pretending to implement them here would be worse than
  naming them.
