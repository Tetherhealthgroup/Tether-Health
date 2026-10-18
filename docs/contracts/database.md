# Database contract v1

Migration sources of truth include `supabase/migrations/202609110001_profiles.sql`,
`supabase/migrations/202609260001_program_data.sql`,
`supabase/migrations/202610170002_enrolments.sql`,
`supabase/migrations/202610180001_sync_tables.sql` and
`supabase/migrations/202610180002_service_session_guard.sql`.

Every migration file is named `YYYYMMDDNNNN_name.sql`: a 12-digit version (date
plus a four-digit sequence), then lowercase letters, digits and underscores.
`supabase/tests/verify_migration_names.sh` checks in the static migration checks
that every name has this form and that versions are unique and strictly
increasing in filename order. It cannot tell whether a new file was given a
version below an existing one, so give each new migration a version later than
every existing file.

`public.profiles` is a one-to-one extension of `auth.users`; `id` is both its
primary key and cascading foreign key. A signup trigger creates the row. Clients
cannot choose another user's identity: RLS predicates use `auth.uid()`.

| Column | Contract |
|---|---|
| `id` | UUID, immutable identity, references `auth.users(id)` |
| `display_name` | nullable trimmed text, 1–80 characters when present |
| `locale` | `en` or `es` |
| `time_zone` | non-empty time-zone identifier, max 64 characters |
| `onboarding_completed` | boolean, defaults false |
| `avatar_path` | nullable private path under `<user-id>/`, max 512 characters |
| `account_deletion_started_at` | nullable server-managed avatar-write barrier; omitted from client/export DTOs |
| `created_at` / `updated_at` | UTC timestamps; database managed |

Authenticated users may select and update only their row. Insert is performed by
the trusted signup trigger; direct delete is not granted. The controlled
`delete_my_app_data('DELETE')` security-definer function derives the caller from
`auth.uid()`, deletes only that profile and its cascading quit plan, and returns
row counts. Avatar objects use a private bucket and must live under a folder
matching `auth.uid()`. Inserts and updates lock the caller's profile row and are
denied after `account_deletion_started_at` is set or the profile no longer exists.
Profile responses provide a caller-authenticated signed URL with a five-minute
lifetime for private avatar display.

## Program module snapshots

`public.program_data` contains at most one caller-owned snapshot for each of
`heartwise`, `steady`, and `clearair`. The composite primary key is
`(user_id, program_id)`; RLS applies `auth.uid() = user_id` to select, insert,
update, and delete. Payloads must be JSON objects no larger than 32 KiB and use a
bounded positive revision. Flutter keeps the same snapshot in platform secure
storage, partitioned by account ID (or an isolated guest scope), and retries
sync after offline saves. Program payloads are prohibited from logs.

## Programmes, enrolments and consents

Migration source of truth: `supabase/migrations/202610170002_enrolments.sql`.
Programme health data hangs off an enrolment, never off the account, and
consent is recorded per enrolment, purpose and recipient. Every table below
has row-level security enabled and forced; `anon` has no access.

`public.programmes` is read-only reference data, readable by authenticated
users. It holds exactly the 11 programmes of the `tether_ui` spec, keyed by a
stable two-letter `code`:

| `code` | `slug` | Name | `receives_resources` |
|---|---|---|---|
| `bf` | `breathefree` | BreatheFree | `smoking_status` |
| `sf` | `scrollfree` | ScrollFree | none |
| `ca` | `clearair` | ClearAir | none |
| `hw` | `heartwise` | Heartwise | `blood_pressure`, `lipids` |
| `st` | `steady` | Steady | `a1c`, `glucose` |
| `re` | `renew` | Renew | `egfr` |
| `nu` | `nourish` | Nourish | none |
| `sd` | `stride` | Stride | none |
| `ea` | `ease` | Ease | none |
| `ck` | `checkup` | Checkup | `immunizations` |
| `be` | `beacon` | Beacon | none |

`receives_resources` lists the health-record categories a programme may
receive, taken from the `records_consent` screen; routing also needs that
enrolment's live `records_import` consent. Ease and ScrollFree never receive
records.

`public.enrolments` has one row per user and programme
(`unique (user_id, programme_code)`); rejoining reuses the row. Leaving keeps
the enrolment and its data until the member deletes them ("Delete now") or
deletes the account; nothing is purged automatically.

| Column | Contract |
|---|---|
| `id` | UUID; programme data references it with `on delete cascade` |
| `user_id` | `auth.users(id)`, cascading |
| `programme_code` | `programmes(code)` |
| `status` | `focus` (default), `learn_only`, `paused` or `left` |
| `mode` | null, or `quit` / `reduce` for `bf` and `sf` only |
| `joined_at` | set on insert |
| `left_at` | database managed: set when the status changes to `left`, cleared on rejoin. Clients cannot write it |

Callers select, insert, update and delete only their own rows. Inserts may set
`user_id`, `programme_code`, `status` (not `left`) and `mode`; updates may set
`status` and `mode` only. "Delete now" on leaving deletes the row, which
cascades to its consents and programme data.

At most two enrolments per user may have `status = 'focus'`. A deferred
constraint trigger checks this at commit, under a per-user advisory lock, so a
swap (one programme to `focus`, another out of it) succeeds in one transaction
in either order, while a third focus programme is refused. `learn_only` and
`paused` are not limited. The default status on insert is `focus`, so a third
enrolment must be inserted with another status.

`public.programme_consents` records one consent per enrolment × purpose ×
recipient. `purpose` is `core`, `reminders`, `records_import`,
`share_care_team`, `share_caregiver`, `research` or `screen_time`.
`recipient_ref` is required for the two sharing purposes and must be null for
all others, so sharing cannot be consented without a named recipient. Each row
keeps `consent_version` and the exact `consent_text` shown, plus `granted_at`
(database set). At most one live (unrevoked) row exists per enrolment, purpose
and recipient, enforced by a partial unique index on live rows only, so a
revocation never conflicts with earlier history. A row is never edited except to revoke it: the only update
allowed is setting `revoked_at`, which the database stamps with the current
time; a revoked row cannot be revived, and a new grant is a new row. Callers
cannot delete consent rows; they go when the enrolment or the account is
deleted. A caller may add a consent only to their own enrolment that is not
`left`, and any purpose other than `core` requires that enrolment's `core`
consent to be live.

Revoking an enrolment's `core` consent revokes every live consent of that
enrolment. Leaving (status changes to `left`) revokes every live consent except
`core`; the `core` row stays live but grants nothing while the enrolment is
left. After rejoining, or after granting `core` again, sharing, records import,
research, screen time and reminders are off until the member grants each one
again. The revoked rows stay as history. Both rules are triggers that run as
the caller.

Consent rows store the wording itself. When approved consent texts exist, a
`consent_documents` reference is planned to identify the exact document version.

`public.account_consents` holds account-level items that belong to no
programme: `essential`, `cross_program_insights` and `diagnostics`. It has the
same version, wording, single-live-row (partial unique index on
`(user_id, purpose)` where not revoked) and revoke-only rules, keyed by
`user_id`. It holds no health data.

`public.has_consent(enrolment_id uuid, purpose text, recipient_ref text default null)`
is a `stable security invoker` function. It is true only when the caller owns
the enrolment, the enrolment is not `left`, the caller's account deletion has
not started, a live consent exists for exactly that purpose and recipient, and
— for any purpose other than `core` — the enrolment's `core` consent is live.
Because it runs as the caller, RLS also applies. Programme-data tables use it
in their insert checks together with "enrolment is not `left`".

`public.deletion_barrier_open()` is a `volatile security invoker` function. It
is true while the caller's profile exists and
`profiles.account_deletion_started_at` is null. It takes a `FOR SHARE` lock on
that profile row, so `begin_account_deletion` waits for in-flight inserts, and
later inserts see the barrier. Every insert policy on enrolments, programme
consents and account consents uses it. Later tables that hold the caller's data
must use it in their insert checks too, alongside `has_consent` where the data
belongs to a programme.

## Sync tables

Migration source of truth: `supabase/migrations/202610180001_sync_tables.sql`.
The `sync/` service stores plan and questionnaire answers and lapses here, per
programme. Enrolment and consent are not stored here: they stay in
`enrolments` and `programme_consents`, so sync is never a second consent store.
Every table below has row-level security enabled and forced; `anon` has no
access, and nothing can be deleted directly.

| Table | Key | Contents |
|---|---|---|
| `sync_account` | `user_id` → `auth.users(id)`, cascading | per-user change counter `change_seq`; `created_at`, `updated_at`. No health data |
| `sync_area` | `(user_id, programme_code)`; `user_id` → `sync_account`, `enrolment_id` → `enrolments(id)` (unique), both cascading; `programme_code` → `programmes(code)` | `revision`, `change_seq`, `updated_at`. A trigger requires the enrolment to be the same user's enrolment in the same programme |
| `sync_answer` | primary key `(user_id, programme_code, screen_id)`; `(user_id, programme_code)` → `sync_area`, cascading | `payload`: a JSON object of at most 32 KiB; `screen_id` matches `^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$` (no `/`); `updated_at` |
| `sync_lapse` | primary key `(user_id, programme_code, ordinal)`; `(user_id, programme_code)` → `sync_area`, cascading | `at`, `severity` (up to 64 characters), `context` (a JSON array, at most 32 KiB). Append-only |

**Reads.** Authenticated callers select only their own rows
(`auth.uid() = user_id`). The API's Today, summary and export read these tables
with the caller's token.

**Writes.** Only the sync service writes. It connects as the role `thsync`:
`NOLOGIN NOINHERIT` in the migration, never superuser and never `BYPASSRLS`,
owning nothing, with no direct grants, and a member of `authenticated` only.
Per transaction it runs `SET LOCAL ROLE authenticated` and sets
`request.jwt.claims` to `{"sub":"<verified subject>","role":"authenticated"}`,
so the same `auth.uid()` policies apply as through PostgREST. Insert and update
policies also require `public.sync_writer_session()` (the session user is
`thsync`), so a PostgREST session cannot write sync data. Every insert and
update check also requires `deletion_barrier_open()`, and for areas, answers
and lapses the enrolment's live `core` consent (`has_consent`). So no data is
written for a programme without an enrolment and core consent, after leaving
it, after its core consent is revoked, or once account deletion has started.
Column grants limit writes to: `sync_account` insert `user_id`, update
`change_seq`; `sync_area` insert `user_id, enrolment_id, programme_code,
revision, change_seq`, update `revision, change_seq`; `sync_answer` insert
`user_id, programme_code, screen_id, payload`, update `payload`; `sync_lapse`
insert only. A trigger refuses every update to `sync_lapse`, for every role.
Giving `thsync` a login is a human step outside migrations; no credential is
stored in this repository.

**The sync session writes nothing else.** Every insert, update and delete
policy outside `sync_*` also requires `not public.sync_writer_session()`:
`profiles`, `quit_plans`, `program_data`, `enrolments`, `programme_consents`,
`account_consents` and the avatar policies on `storage.objects`. For insert
and update policies the condition is in `with check` (the row being written),
so the write fails with `42501`; for delete policies it is in `using`, so no
row qualifies. The `using` clause of update policies is unchanged, because
`select … for share` also applies it and `deletion_barrier_open()` reads the
caller's profile that way during sync writes. Select policies are unchanged,
so a sync session still reads the caller's enrolments, consents and profile,
which `has_consent` and `deletion_barrier_open` need. `begin_account_deletion`
and `delete_my_app_data` refuse a sync session with `TH009`, and
`save_program_data` refuses it with `TH010`. Source:
`supabase/migrations/202610180002_service_session_guard.sql`. Any later
function that writes and is executable by `authenticated` refuses a sync
session the same way, and any later write policy carries the condition;
`supabase/tests/verify_service_session_guard.sh` checks both.

**Leaving and deletion.** Leaving a programme keeps its sync rows, read-only.
"Delete now" deletes the enrolment, which cascades to its `sync_area`, answers
and lapses. Account deletion goes through the API only: `delete_my_app_data`
deletes the caller's sync rows, returns a count for each sync table, and
refuses to run in a `thsync` session (`TH009`), as does
`begin_account_deletion`.

The migration starts by dropping the earlier `sync_*` tables (keyed by
`account_id`) if they exist and are empty. It stops instead if a table with
one of those names has another shape or holds rows, or if another object
depends on one of them (the drop does not cascade). The migration also stops
unless `thsync` is a member of `authenticated` only, without admin option or
inheritance.

The SQL tests in `supabase/tests/verify_sync_migration.sh` and
`supabase/tests/verify_service_session_guard.sh` (run when `VERIFY_DB_URL` is
set) require a superuser connection: they use `SET SESSION AUTHORIZATION` to
act as the `thsync` and `authenticator` logins, and fail if the connection is
not a superuser.

## Quit-plan snapshot

Migration sources of truth:
`supabase/migrations/202609150001_quit_plans.sql`,
`supabase/migrations/202609150002_quit_plan_validator_grant.sql`,
`supabase/migrations/202609150003_quit_plan_upsert_grant.sql`,
`supabase/migrations/202609150004_quit_plan_integrity.sql`,
`supabase/migrations/202609150005_quit_plan_contract_hardening.sql`, and
`supabase/migrations/202610170001_quit_plan_options.sql`.

`public.quit_plans` stores one complete plan snapshot per authenticated user.
`user_id` is both the primary key and a cascading foreign key to `profiles.id`.
The API writes the caller identity from the verified JWT; clients cannot select
another owner. RLS permits authenticated users to select, insert, and update only
the row where `auth.uid() = user_id`.

The snapshot contains the bounded values represented by onboarding: baseline
cigarette-use range, trigger identifiers and optional custom trigger, readiness
and quit paths, quit date/check-in preference, selected and top reasons,
bounded synthetic support-person objects, preparation tasks, and treatment or
care-team reminder preferences. PostgreSQL checks constrain every enum, array
size, custom text length, nested support-person shape, and top-reason membership.
The database manages creation and update timestamps.

### Quit-plan option values

The BreatheFree onboarding screens in the `tether_ui` spec show labels; clients
store the values below. The API (`PUT /v1/quit-plan`,
`POST /v1/quit-plan/guest-import`) and the PostgreSQL checks accept exactly
these values. Changes are additive: a value accepted earlier stays accepted, so
existing rows remain valid.

| Field | Spec screen | Label → stored value |
|---|---|---|
| `daily_cigarette_use` | `bf_q1` | "I don’t smoke every day" → `notEveryDay`; "10 or fewer" → `tenOrFewer`; "11–20" → `elevenToTwenty`; "21–30" → `twentyOneToThirty`; "31 or more" → `thirtyOneOrMore` |
| `smoking_triggers` | `bf_q2` | "Stress" → `stress`; "After meals" → `afterMeals`; "Driving" → `driving`; "With coffee" → `coffee`; "Social" → `socialSettings`; "Work breaks" → `workBreaks`; "Alcohol" → `alcohol`; "Boredom" → `boredom`; "Morning" → `morning`; "Scrolling" → `scrolling` |
| `custom_smoking_trigger` | `bf_q2` | "Add your own" free text, 1–120 trimmed characters |
| `quit_reasons`, `top_quit_reason` | `bf_q3` | "Protect my family" → `family`; "Breathe easier" → `breatheEasier`; "Save money" → `saveMoney`; "Feel in control" → `control`; "My health" → `improveHealth`; "Be there for my future" → `future` |
| `quit_plan_path` | `bf_path` | "Set a quit date" → `setQuitDate`; "Quit today" → `quitToday`; "Reduce gradually" → `reduceGradually`; "Explore first" → `exploreFirst` |
| `readiness_path` | `bf_path` | "Explore first" → `explore` (required with `exploreFirst`); the other three paths use the default `prepare` |
| `preparation_tasks` | `bf_support` | "Remove cigarettes, lighters, ashtrays" → `removeSupplies`; "Make home and car smoke-free" → `smokeFreeSpaces`; "Stock gum, water or snacks" → `stockAlternatives` |

Legacy values that the current screens no longer offer stay valid for existing
rows and older clients: trigger `beforeBed`, reason `custom` (with
`custom_quit_reason`), and readiness `connect`. Because `beforeBed` and
`scrolling` are both allowed, `smoking_triggers` holds up to 11 unique values.
`quit_plan_path = 'exploreFirst'` requires `readiness_path = 'explore'`; both the
API (HTTP 400) and a check constraint enforce it. `quit_date` is still required
on every row. The spec's "Explore first" branch sets no date and does not call
`PUT /v1/quit-plan`, so storing an explore-only plan without a date would need
a separate contract change.

This table is development-only until privacy, clinical, consent, retention,
deletion, and compliance review is complete. Only synthetic data may be entered
in `breathefree-dev`; real patient or support-person information is prohibited.

## Account-data deletion

Migration sources of truth:
`supabase/migrations/202609200001_account_data_deletion.sql`,
`supabase/migrations/202610030001_avatar_deletion_barrier.sql`,
`supabase/migrations/202610170002_enrolments.sql`,
`supabase/migrations/202610180001_sync_tables.sql` and
`supabase/migrations/202610180002_service_session_guard.sql`.

`delete_my_app_data` deletes the caller's sync lapses, answers, areas and sync
account, programme consents, enrolments (and everything that cascades from
them), account consents, program data, quit plan and profile. It returns counts
only, one for each table it deletes from: `profiles`, `quit_plans`,
`program_data`, `enrolments`, `programme_consents`, `account_consents`,
`sync_answers`, `sync_lapses`, `sync_areas` and `sync_accounts`.
Consent history is deleted with the account; nothing records what was deleted.
It and `begin_account_deletion` refuse to run in a sync service (`thsync`)
session (`TH009`).

The NestJS API first invokes `begin_account_deletion` with exact confirmation.
That function updates the caller's profile row, waiting for any upload holding a
conflicting `FOR SHARE` lock and durably blocking subsequent avatar
inserts/updates. The
API's server-only client then uses flat cursor pagination to enumerate every
object under the exact `<verified-subject>/` prefix and removes those objects in
bounded batches. It never accepts a user ID in the request body. Only after
Storage succeeds does `delete_my_app_data` remove database rows, followed by
deletion of that verified subject's Auth identity. Failed attempts are safe to
retry: the write barrier remains set until the profile is removed, cleanup is
idempotent, and a missing Auth identity is success. API receipts contain only
request/completion identifiers and deleted counts, never user payloads.

The Flutter client persists an encrypted deletion-intent tombstone before it
calls the destructive API and aborts if that prerequisite fails or times out.
After a successful response, session invalidation and bounded local program and
quit-plan cleanup start without waiting for receipt persistence. The exact
receipt is upgraded into a separate encrypted key while the tombstone remains a
durable fallback; a throwing or stalled post-success write cannot block cleanup.
Pending receipts or intent-only tombstones are restored after interruption and
local cleanup is safe to repeat. **Done** clears both records. An intent-only
recovery reports that no server receipt was restored rather than inventing an
identifier or claiming a receipt survived.

## Error codes

Errors raised by our own database functions and triggers use SQLSTATE class
`TH`, which PostgreSQL does not use. Each is raised as
`raise exception using errcode = 'TH0nn', message = '…', hint = '<name>'`,
where the hint is the snake_case name below. Callers (the API) match the
`code`, never the message text. PostgREST passes `code`, `message` and `hint`
through and answers HTTP 400 for codes it does not know; the API maps them to
its own responses. Messages and hints never contain user data. A new error
takes the next free code and adds a row here;
`supabase/tests/verify_service_session_guard.sh` fails when a migration raises
a `TH` code that is not in this table, or with a different hint.

| Code | Name | Raised by | Message |
|---|---|---|---|
| `TH001` | `focus_cap_reached` | `enrolments_focus_cap` (deferred trigger on `enrolments`, at commit) | At most two programmes can be in focus |
| `TH002` | `consent_already_revoked` | `consent_revoke_only` (update trigger on `programme_consents` and `account_consents`) | Consent is already revoked |
| `TH003` | `consent_immutable` | `consent_revoke_only` | Consent can only be revoked; Consent records are immutable |
| `TH004` | `consent_requires_core` | Reserved. Today an optional consent without a live core consent is refused by row-level security (`42501`) | — |
| `TH005` | `enrolment_left` | Reserved. Today a write to a left enrolment is refused by row-level security (`42501`) | — |
| `TH006` | `deletion_in_progress` | Reserved. Today a write after `begin_account_deletion` is refused by row-level security (`42501`) | — |
| `TH007` | `sync_area_mismatch` | `sync_area_match_enrolment` (trigger on `sync_area`) | Sync area must match its enrolment |
| `TH008` | `lapses_append_only` | `sync_lapse_append_only` (update trigger on `sync_lapse`) | Lapses are append-only |
| `TH009` | `deletion_via_api_only` | `begin_account_deletion` and `delete_my_app_data` in a sync service session | Account deletion goes through the API |
| `TH010` | `sync_session_refused` | `save_program_data` in a sync service session | The sync service writes only sync tables |

Standard SQLSTATEs are kept where PostgreSQL defines the condition:
`42501` for row-level security and privilege refusals and for
"Authentication required" (no caller); `23514` for check constraints and for
the deletion functions' "Explicit confirmation required" and "Account deletion
was not started"; `23505` for unique keys; `23503` for foreign keys.
