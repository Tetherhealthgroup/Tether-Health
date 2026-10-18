# Database contract v1

Migration sources of truth include `supabase/migrations/202609110001_profiles.sql`,
`supabase/migrations/202609260001_program_data.sql` and
`supabase/migrations/202610170002_enrolments.sql`.

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
and recipient. A row is never edited except to revoke it: the only update
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
same version, wording, single-live-row and revoke-only rules, keyed by
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
`supabase/migrations/202610030001_avatar_deletion_barrier.sql` and
`supabase/migrations/202610170002_enrolments.sql`.

`delete_my_app_data` deletes the caller's programme consents, enrolments (and
everything that cascades from them), account consents, program data, quit plan
and profile. It returns counts only: `profiles`, `quit_plans`, `program_data`,
`enrolments`, `programme_consents` and `account_consents`. Consent history is
deleted with the account; nothing records what was deleted.

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
