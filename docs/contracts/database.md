# Database contract v1

Migration sources of truth include `supabase/migrations/202609110001_profiles.sql`
and `supabase/migrations/202609260001_program_data.sql`.

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

## Quit-plan snapshot

Migration sources of truth:
`supabase/migrations/202609150001_quit_plans.sql`,
`supabase/migrations/202609150002_quit_plan_validator_grant.sql`,
`supabase/migrations/202609150003_quit_plan_upsert_grant.sql`,
`supabase/migrations/202609150004_quit_plan_integrity.sql`, and
`supabase/migrations/202609150005_quit_plan_contract_hardening.sql`.

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

This table is development-only until privacy, clinical, consent, retention,
deletion, and compliance review is complete. Only synthetic data may be entered
in `breathefree-dev`; real patient or support-person information is prohibited.

## Account-data deletion

Migration sources of truth:
`supabase/migrations/202609200001_account_data_deletion.sql` and
`supabase/migrations/202610030001_avatar_deletion_barrier.sql`.

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
