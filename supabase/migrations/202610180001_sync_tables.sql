begin;

-- Sync tables for the thsync service (plan and questionnaire answers, lapses).
--
-- * Programme data hangs off an enrolment: public.sync_area references
--   public.enrolments(id) on delete cascade, and answers and lapses hang off
--   sync_area. "Delete now" on an enrolment removes its sync data; leaving
--   (status left) keeps it, read-only, until the member deletes it.
-- * Enrolment and consent stay in public.enrolments and
--   public.programme_consents. These tables hold no enrolment status and no
--   sharing settings, so sync can never become a second consent store.
-- * Row-level security is enabled and forced on every table. Authenticated
--   callers read only their own rows (the API reads them with the caller's
--   token). Writes are accepted only from a thsync session: the service logs
--   in as the non-privileged role thsync, then per transaction runs
--   SET LOCAL ROLE authenticated and sets request.jwt.claims to the verified
--   subject, so the same auth.uid() policies apply. A PostgREST session (whose
--   session user is never thsync) cannot write here.
-- * Every write needs the enrolment's live core consent (has_consent), and
--   every insert or update check uses deletion_barrier_open().
-- * Lapses are append-only: insert is the only write granted, and a trigger
--   refuses UPDATE for every role. They are deleted only by cascade or by
--   delete_my_app_data.
-- * delete_my_app_data also deletes the caller's sync rows and returns
--   sync_answers and sync_lapses counts.
-- * thsync is created NOLOGIN here. Giving it LOGIN is a separate human step
--   outside migrations; no credential belongs in this repository.

-- Legacy cleanup. An earlier, unmerged design defined sync_* tables keyed by
-- account_id. Drop them if present. If tables with these names exist but do
-- not have that legacy shape, stop instead of dropping them.
do $legacy$
begin
  if exists (
    select 1
    from pg_catalog.pg_class as c
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('sync_account', 'sync_area', 'sync_answer', 'sync_lapse')
      and not exists (
        select 1
        from pg_catalog.pg_attribute as a
        where a.attrelid = c.oid
          and a.attname = 'account_id'
          and not a.attisdropped
      )
  ) then
    raise exception 'public.sync_* exists without the legacy account_id column; refusing to drop it';
  end if;
end;
$legacy$;

drop table if exists public.sync_lapse, public.sync_answer, public.sync_area, public.sync_account cascade;

-- The service role. No login, no inheritance (it must SET ROLE authenticated
-- to do anything), no elevated attributes, and it owns nothing.
do $role$
begin
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'thsync') then
    create role thsync nologin noinherit;
  end if;
  if exists (
    select 1
    from pg_catalog.pg_roles
    where rolname = 'thsync'
      and (rolsuper or rolbypassrls or rolcreaterole or rolcreatedb or
           rolreplication or rolinherit)
  ) then
    raise exception 'role thsync must be non-privileged and noinherit';
  end if;
end;
$role$;

grant authenticated to thsync;

-- True only when the database session was opened by the sync service.
-- session_user is the login role and is not changed by SET ROLE; PostgREST
-- sessions log in as a different role, so they can never pass this check.
create function public.sync_writer_session()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select session_user = 'thsync';
$$;

comment on function public.sync_writer_session() is
  'True when the session user is thsync. Write policies on sync_* require it, so only the sync service writes sync data.';

create table public.sync_account (
  user_id uuid primary key references auth.users(id) on delete cascade,
  change_seq bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sync_account_change_seq_check check (change_seq >= 0)
);

comment on table public.sync_account is
  'Per-user sync cursor. Holds no health data. Written only by the sync service.';

create table public.sync_area (
  user_id uuid not null references public.sync_account(user_id) on delete cascade,
  enrolment_id uuid not null references public.enrolments(id) on delete cascade,
  programme_code text not null references public.programmes(code),
  revision bigint not null,
  change_seq bigint not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, programme_code),
  constraint sync_area_enrolment_key unique (enrolment_id),
  constraint sync_area_revision_check check (revision >= 0),
  constraint sync_area_change_seq_check check (change_seq >= 0)
);

comment on table public.sync_area is
  'One row per enrolment that has synced: revision and change counter only. No enrolment status or sharing settings (those live in enrolments and programme_consents). Deleted with the enrolment.';

create index sync_area_change_seq_idx
on public.sync_area (user_id, change_seq);

-- The enrolment must be the caller's enrolment in the same programme, so an
-- area can never file one programme's data under another programme's consent.
create function public.sync_area_match_enrolment()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.enrolments as e
    where e.id = new.enrolment_id
      and e.user_id = new.user_id
      and e.programme_code = new.programme_code
  ) then
    raise check_violation using message = 'Sync area must match its enrolment';
  end if;
  return new;
end;
$$;

create trigger sync_area_match_enrolment
before insert or update of user_id, enrolment_id, programme_code
on public.sync_area
for each row execute function public.sync_area_match_enrolment();

create table public.sync_answer (
  user_id uuid not null,
  programme_code text not null,
  screen_id text not null,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, programme_code, screen_id),
  constraint sync_answer_area_fkey foreign key (user_id, programme_code)
    references public.sync_area(user_id, programme_code) on delete cascade,
  constraint sync_answer_screen_id_check check (
    screen_id ~ '^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$'
  ),
  constraint sync_answer_payload_check check (
    jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 32768
  )
);

comment on table public.sync_answer is
  'Plan and questionnaire answers per programme and screen (JSON object, at most 32 KiB). Never logged.';

create table public.sync_lapse (
  user_id uuid not null,
  programme_code text not null,
  ordinal integer not null,
  at timestamptz not null,
  severity text not null default '',
  context jsonb not null default '[]'::jsonb,
  primary key (user_id, programme_code, ordinal),
  constraint sync_lapse_area_fkey foreign key (user_id, programme_code)
    references public.sync_area(user_id, programme_code) on delete cascade,
  constraint sync_lapse_ordinal_check check (ordinal >= 0),
  constraint sync_lapse_severity_check check (char_length(severity) <= 64),
  constraint sync_lapse_context_check check (
    jsonb_typeof(context) = 'array' and octet_length(context::text) <= 32768
  )
);

comment on table public.sync_lapse is
  'Recorded lapses per programme. Append-only: rows are inserted, never updated, and removed only with their programme or account. Never logged.';

create function public.sync_lapse_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise check_violation using message = 'Lapses are append-only';
end;
$$;

create trigger sync_lapse_append_only
before update on public.sync_lapse
for each row execute function public.sync_lapse_append_only();

create trigger sync_account_set_updated_at
before update on public.sync_account
for each row execute function public.set_updated_at();

create trigger sync_area_set_updated_at
before update on public.sync_area
for each row execute function public.set_updated_at();

create trigger sync_answer_set_updated_at
before update on public.sync_answer
for each row execute function public.set_updated_at();

alter table public.sync_account enable row level security;
alter table public.sync_account force row level security;
alter table public.sync_area enable row level security;
alter table public.sync_area force row level security;
alter table public.sync_answer enable row level security;
alter table public.sync_answer force row level security;
alter table public.sync_lapse enable row level security;
alter table public.sync_lapse force row level security;

create policy "sync_account_select_own"
on public.sync_account for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "sync_account_insert_sync"
on public.sync_account for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open()
);

create policy "sync_account_update_sync"
on public.sync_account for update
to authenticated
using ((select auth.uid()) = user_id and public.sync_writer_session())
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open()
);

create policy "sync_area_select_own"
on public.sync_area for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "sync_area_insert_sync"
on public.sync_area for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open() and
  exists (
    select 1
    from public.enrolments as e
    where e.id = sync_area.enrolment_id
      and e.user_id = (select auth.uid())
      and e.programme_code = sync_area.programme_code
  ) and
  public.has_consent(sync_area.enrolment_id, 'core')
);

create policy "sync_area_update_sync"
on public.sync_area for update
to authenticated
using ((select auth.uid()) = user_id and public.sync_writer_session())
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open() and
  public.has_consent(sync_area.enrolment_id, 'core')
);

create policy "sync_answer_select_own"
on public.sync_answer for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "sync_answer_insert_sync"
on public.sync_answer for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open() and
  exists (
    select 1
    from public.sync_area as a
    where a.user_id = sync_answer.user_id
      and a.programme_code = sync_answer.programme_code
      and public.has_consent(a.enrolment_id, 'core')
  )
);

create policy "sync_answer_update_sync"
on public.sync_answer for update
to authenticated
using ((select auth.uid()) = user_id and public.sync_writer_session())
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open() and
  exists (
    select 1
    from public.sync_area as a
    where a.user_id = sync_answer.user_id
      and a.programme_code = sync_answer.programme_code
      and public.has_consent(a.enrolment_id, 'core')
  )
);

create policy "sync_lapse_select_own"
on public.sync_lapse for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "sync_lapse_insert_sync"
on public.sync_lapse for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.sync_writer_session() and
  public.deletion_barrier_open() and
  exists (
    select 1
    from public.sync_area as a
    where a.user_id = sync_lapse.user_id
      and a.programme_code = sync_lapse.programme_code
      and public.has_consent(a.enrolment_id, 'core')
  )
);

-- Grants. No delete on any sync table and no update on lapses. thsync gets
-- nothing directly: it acts only as authenticated, under the policies above.
revoke all on table public.sync_account from anon, authenticated;
revoke all on table public.sync_area from anon, authenticated;
revoke all on table public.sync_answer from anon, authenticated;
revoke all on table public.sync_lapse from anon, authenticated;
grant select on table public.sync_account to authenticated;
grant select on table public.sync_area to authenticated;
grant select on table public.sync_answer to authenticated;
grant select on table public.sync_lapse to authenticated;
grant insert (user_id) on table public.sync_account to authenticated;
grant update (change_seq) on table public.sync_account to authenticated;
grant insert (user_id, enrolment_id, programme_code, revision, change_seq)
on table public.sync_area to authenticated;
grant update (revision, change_seq) on table public.sync_area to authenticated;
grant insert (user_id, programme_code, screen_id, payload)
on table public.sync_answer to authenticated;
grant update (payload) on table public.sync_answer to authenticated;
grant insert (user_id, programme_code, ordinal, at, severity, context)
on table public.sync_lapse to authenticated;

revoke all on function public.sync_writer_session()
from public, anon, authenticated;
grant execute on function public.sync_writer_session() to authenticated;
revoke all on function public.sync_area_match_enrolment()
from public, anon, authenticated;
revoke all on function public.sync_lapse_append_only()
from public, anon, authenticated;

-- Account deletion also removes the caller's sync data. Everything earlier
-- migrations put in this function is kept; the additions are the sync deletes
-- (before enrolments, so their counts are not lost to the cascade), the two
-- sync counts in the receipt, and a refusal for sync sessions (deletion goes
-- through the API only).
create or replace function public.delete_my_app_data(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  deleted_profiles integer := 0;
  deleted_quit_plans integer := 0;
  deleted_program_data integer := 0;
  deleted_enrolments integer := 0;
  deleted_programme_consents integer := 0;
  deleted_account_consents integer := 0;
  deleted_sync_answers integer := 0;
  deleted_sync_lapses integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise insufficient_privilege using message = 'Account deletion goes through the API';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;
  if exists (
    select 1
    from public.profiles
    where id = caller_id and account_deletion_started_at is null
  ) then
    raise check_violation using message = 'Account deletion was not started';
  end if;

  delete from public.sync_lapse where user_id = caller_id;
  get diagnostics deleted_sync_lapses = row_count;
  delete from public.sync_answer where user_id = caller_id;
  get diagnostics deleted_sync_answers = row_count;
  delete from public.sync_area where user_id = caller_id;
  delete from public.sync_account where user_id = caller_id;
  delete from public.programme_consents
  where enrolment_id in (
    select id from public.enrolments where user_id = caller_id
  );
  get diagnostics deleted_programme_consents = row_count;
  delete from public.enrolments where user_id = caller_id;
  get diagnostics deleted_enrolments = row_count;
  delete from public.account_consents where user_id = caller_id;
  get diagnostics deleted_account_consents = row_count;
  delete from public.program_data where user_id = caller_id;
  get diagnostics deleted_program_data = row_count;
  delete from public.quit_plans where user_id = caller_id;
  get diagnostics deleted_quit_plans = row_count;
  delete from public.profiles where id = caller_id;
  get diagnostics deleted_profiles = row_count;

  return jsonb_build_object(
    'profiles', deleted_profiles,
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data,
    'enrolments', deleted_enrolments,
    'programme_consents', deleted_programme_consents,
    'account_consents', deleted_account_consents,
    'sync_answers', deleted_sync_answers,
    'sync_lapses', deleted_sync_lapses
  );
end;
$$;

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;
grant execute on function public.delete_my_app_data(text) to authenticated;

commit;
