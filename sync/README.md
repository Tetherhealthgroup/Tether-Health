# Tether Health sync service

A FastAPI service that syncs a person's programme answers and lapses between
their devices, **one programme at a time**.

It stores one segregated bundle per programme — that programme's answers and
lapses — because 42 CFR Part 2 treats each substance-use programme's record as
separately consented and separately revocable. Enrolment and consent are not
stored here: they belong to the API (`enrolments`, `programme_consents`). This
service reads the caller's enrolment to file data under it and refuses to write
for a programme without a live core consent.

Every design decision below is explained where it lives; the docstrings are the
documentation and this file is the map.

| I want to know… | Read |
| --- | --- |
| why the unit of sync is a programme, the conflict policy, lapses and deletion | `thsync/repository.py` module docstring |
| the request/response shapes and their validation | `thsync/wire.py` |
| what may and may not go into a log | `thsync/logs.py` |
| why error bodies say so little | `thsync/problems.py` |
| the tables, and how they relate to the migration | `thsync/schema.py` |
| the database login, per-transaction identity and start-up refusal | `thsync/db.py` |
| token verification | `thsync/auth.py` |

---

## Running it

```bash
python3.12 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt -r requirements-postgres.txt

export THSYNC_SUPABASE_URL='https://<project-ref>.supabase.co'
export THSYNC_DATABASE_URL='postgresql+psycopg://thsync:<password>@<host>/postgres'

uvicorn --factory thsync.app:create_app --port 8080
```

`create_app` is a factory, not a module-level `app`, so tests can hand it their
own engine. `--factory` is therefore required.

**The database login must be the role `thsync`.** It is created `NOLOGIN` by
`supabase/migrations/202610180001_sync_tables.sql`; giving it a login and a
password is a manual step on the server, and the password lives only in the
deployment's secret store. At start-up the service refuses to run if its login
is a superuser, bypasses row-level security, can act as a privileged role
(`postgres`, `service_role`, …), is not `thsync`, has a role set at session
level, or is a member of anything but `authenticated`. Every transaction then
runs `SET LOCAL ROLE authenticated` and sets `request.jwt.claims` to the
verified subject, so the row-level security policies apply to every statement.

For local work against SQLite (no row-level security; not for real data):

```bash
export THSYNC_ENVIRONMENT=development
export THSYNC_JWT_SECRET='<a local test secret, 32+ characters>'
export THSYNC_DATABASE_URL='sqlite+pysqlite:///./thsync.db'
python -c 'from thsync.config import settings_from_env as s; from thsync.db import *; create_schema(create_engine_from_settings(s()))'
uvicorn --factory thsync.app:create_app --port 8080
```

### Tests

```bash
pip install -r requirements-dev.txt
pytest          # in-process; only loopback network
mypy            # strict
```

Most tests run against in-memory SQLite, and every statement they run is also
parsed with PostgreSQL's own grammar (`pglast`). `tests/test_postgres.py` runs
the service against a real PostgreSQL server with every migration applied, and
drives it through the `thsync` login. It runs when `THSYNC_TEST_DATABASE_URL`
names a superuser connection to a local server (127.0.0.1 or localhost) and is
skipped otherwise; CI runs it against a PostgreSQL 17 service container with
`THSYNC_REQUIRE_POSTGRES=1`, so a skip there is a failure. It applies
`tests/postgres/supabase_stand_in.sql` first: minimal Supabase roles, `auth`
and `storage`, not the Supabase image.

### Migrations

The schema lives in the repository's `supabase/migrations/`, in the
`YYYYMMDDNNNN_name.sql` form, each file wrapped in its own transaction. The
sync tables are created by `202610180001_sync_tables.sql`.
`tests/test_migration_matches_schema.py` compares that file with
`thsync/schema.py` — tables, columns, types, primary keys, defaults and foreign
keys with their cascades — so the two cannot drift silently.

---

## Configuration

| Variable | Required | Default | Meaning |
| --- | --- | --- | --- |
| `THSYNC_ENVIRONMENT` | no | `production` | `production` or `development`. Production accepts only JWKS (ES256) token verification and a PostgreSQL database, and never echoes SQL. |
| `THSYNC_SUPABASE_URL` | in production | — | e.g. `https://<ref>.supabase.co`. Derives the issuer and the JWKS URL. |
| `THSYNC_JWT_JWKS_URL` | no | derived | Overrides the derived key-set URL. |
| `THSYNC_JWT_SECRET` | development only | — | Legacy symmetric HS256 secret. **Refused in production.** Setting both this and a key set is refused everywhere. |
| `THSYNC_DATABASE_URL` | in production | `sqlite+pysqlite:///./thsync.db` (development) | SQLAlchemy URL. Production: `postgresql+psycopg://thsync:…@…` |
| `THSYNC_JWT_AUDIENCE` | no | `authenticated` | Required `aud`. Supabase signs `anon` tokens with the same key, so this check is what keeps the public key out. |
| `THSYNC_JWT_ISSUER` | no | derived from the project URL | Required `iss` when set. |
| `THSYNC_JWT_LEEWAY_SECONDS` | no | `10` | Clock skew tolerated on `exp`/`iat`. |
| `THSYNC_SQL_ECHO` | no | `false` | Echo SQL, development only. **Forced off in production** — statement parameters include answer text. |

---

## API contract

Base path `/v1`. Everything except `/v1/health` needs
`Authorization: Bearer <supabase access token>`. The account is the verified
`sub`, which must be a user id (UUID); there is no account id anywhere in a
path, query or body.

All errors are RFC 7807 `application/problem+json`:

```json
{ "type": "https://tetherhealthgroup.com/problems/unknown-cursor",
  "title": "Conflict", "status": 409, "detail": "…" }
```

### The area bundle

One programme's sync data. `area` is one of the eleven programme codes (`bf`,
`sf`, `ca`, `hw`, `st`, `re`, `nu`, `sd`, `ea`, `ck`, `be`).

```json
{
  "area": "bf",
  "revision": 3,
  "base_revision": 2,
  "answers": {
    "bf/meds": {"chips": {"0": [1, 2]}, "option": {"1": 3},
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
* `answers` keys are `programme/screenId` and the prefix **must** equal `area`.
  A screen's answers take at most 32 KiB. A stored screen that a push no longer
  carries is cleared: stored as `{}`, its old content gone.
* `lapses` are append-only. Their positions are the stored ordinals: a push
  repeats every stored lapse unchanged and may add new ones after them.
* Timestamps must carry an offset. They are returned in UTC as `…Z`.
* Unknown fields — including `enrolment`, `sharing` and `revoked` — are
  rejected (422), not ignored.

### `GET /v1/health`

No auth, no database access. `200 {"status": "ok"}`.

### `POST /v1/sync/pull`

```json
{"cursor": 12, "areas": ["bf"]}
```

`cursor` is `null` for a first sync. `areas` is an optional filter.

```json
{"cursor": 17, "areas": [ …bundles… ], "current_areas": ["bf", "sf"],
 "server_time": "2026-09-15T15:06:50.257Z"}
```

Returns every bundle changed after `cursor`. `current_areas` lists **every**
programme the caller has, whatever the filter or cursor: the client drops any
local area missing from it, together with its unpushed changes — that is how a
deleted programme reaches the person's other devices.

**Filtered pulls and the cursor.** When `areas` is given, the returned cursor
is the highest value below which *nothing was withheld*. A client may be handed
the same bundle twice; it will never be silently skipped past one.
`409 unknown-cursor` if the cursor is ahead of this account's history — pull
from `null` to resynchronise.

### `POST /v1/sync/push`

```json
{"base_cursor": 12, "areas": [ …bundles with base_revision… ]}
```

```json
{"cursor": 19, "applied": ["nu"],
 "conflicts": [
   {"area": "bf", "reason": "stale-revision",
    "base_revision": 1, "server_revision": 2, "server": { …bundle… }}
 ],
 "server_time": "…"}
```

**Conflict policy: per-area optimistic concurrency, reported and never
merged.** If a bundle's `base_revision` does not equal the server's current
revision for that area (including `null` for an area the server holds), that
bundle is not applied and the server's bundle is returned with it. The bundles
that did match are still applied. Always `200` for conflicts. Duplicated areas
in one push are `422`. A whole push is one transaction.

Refused as a whole, with nothing written (each names bundles by position in
`areas`, as `positions`, never by programme):

* `409 area_gone` — a bundle names a programme the caller has no enrolment in,
  or carries a `base_revision` for an area that has since been deleted. Discard
  that area's pending changes.
* `403 consent_required` — a bundle names a programme the caller has left, or
  whose core consent is not live, or account deletion has started.
* `409 lapse_conflict` — a bundle changes or drops a stored lapse, or a new
  lapse collides with one stored meanwhile. Pull, renumber unpushed lapses
  after the server's last one, drop any whose content the server already holds,
  and push again; no lapse is lost to a conflict.

### Deletion

There is no delete route. A programme's sync data is deleted with its
enrolment ("delete now", through the API; the foreign keys cascade), and an
account's with the account (`delete_my_app_data`, through the API, which
refuses a `thsync` session). After account deletion the token no longer
authenticates; the client signs out and wipes its local copy.

---

## PHI handling

* **Logs carry ids and counts only.** Account ids, revisions, cursors, counts,
  refusal reasons, exception types. Never answer text, slider values, chip
  selections, lapse severity or context, tokens or claims. `thsync/logs.py`
  states the rule; `tests/test_errors_and_logs.py` enforces it.
* SQLAlchemy is constructed with `hide_parameters=True`, so a constraint
  violation's traceback does not carry the bound parameters.
* **Error bodies carry positions and codes, never content.**
* The interactive docs (`/docs`, `/redoc`) are disabled. The OpenAPI document
  itself is still served.

## What is not verified here

* The PostgreSQL suite runs against plain PostgreSQL with
  `tests/postgres/supabase_stand_in.sql`, not the Supabase image, and with no
  connection pooler. That `SET LOCAL ROLE` and transaction-local claims behave
  the same through Supavisor in transaction mode is expected but has to be
  checked against the hosted project.
* Concurrency is reasoned about, not load-tested: pushes for one account are
  serialised by a row lock on `sync_account` (`thsync/repository.py`).
* No rate limiting, no request-size limit beyond the per-field bounds in
  `thsync/wire.py`, and no readiness probe. Those belong to whatever fronts
  this service.
