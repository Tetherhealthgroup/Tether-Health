begin;

-- The sync service session writes only the sync tables, and database errors
-- raised by our own functions carry stable SQLSTATE codes.
--
-- * public.sync_writer_session() is true when the session was opened by the
--   sync service (session user thsync). Every insert, update and delete policy
--   outside sync_* now also requires it to be false: profiles, quit_plans,
--   program_data, enrolments, programme_consents, account_consents and the
--   avatar policies on storage.objects. Each policy is re-created with its
--   existing condition unchanged plus "and not public.sync_writer_session()":
--   in the with check clause of insert and update policies (the row being
--   written) and in the using clause of update and delete policies (the rows
--   that can be targeted or locked with SELECT ... FOR UPDATE / FOR SHARE).
-- * One exception: the using clause of profiles_update_own stays as it was.
--   SELECT ... FOR SHARE also applies the update policy's using clause, and
--   deletion_barrier_open() reads the caller's profile that way during every
--   sync write. A sync session's profile update still fails its with check.
-- * Select policies are unchanged, so has_consent() and
--   deletion_barrier_open() still work in a sync session.
-- * begin_account_deletion and delete_my_app_data refuse a sync session
--   (TH009), and save_program_data refuses it too (TH010). save_program_data
--   also returns after a first insert instead of running the update as well,
--   so a first save returns its row once. Everything else in these functions
--   is unchanged.
-- * Custom errors use the SQLSTATE class TH, listed in
--   docs/contracts/database.md: the focus cap (TH001), consent revoke-only
--   rules (TH002, TH003), the sync area enrolment match (TH007), append-only
--   lapses (TH008) and the deletion refusals above. Messages are unchanged;
--   each error also carries its snake_case name as the hint.

-- Profiles ---------------------------------------------------------------------

drop policy "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id and not public.sync_writer_session());

-- Avatar objects -----------------------------------------------------------------

drop policy "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars' and public.avatar_write_allowed(name) and
  not public.sync_writer_session()
);

drop policy "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars' and public.avatar_write_allowed(name) and
  not public.sync_writer_session()
)
with check (
  bucket_id = 'avatars' and public.avatar_write_allowed(name) and
  not public.sync_writer_session()
);

drop policy "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text and
  not public.sync_writer_session()
);

-- Quit plans -------------------------------------------------------------------

drop policy "quit_plans_insert_own" on public.quit_plans;
create policy "quit_plans_insert_own"
on public.quit_plans for insert
to authenticated
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

drop policy "quit_plans_update_own" on public.quit_plans;
create policy "quit_plans_update_own"
on public.quit_plans for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

-- Program data -------------------------------------------------------------------

drop policy "program_data_insert_own" on public.program_data;
create policy "program_data_insert_own"
on public.program_data for insert to authenticated
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

drop policy "program_data_update_own" on public.program_data;
create policy "program_data_update_own"
on public.program_data for update to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

drop policy "program_data_delete_own" on public.program_data;
create policy "program_data_delete_own"
on public.program_data for delete to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session());

-- Enrolments ---------------------------------------------------------------------

drop policy "enrolments_insert_own" on public.enrolments;
create policy "enrolments_insert_own"
on public.enrolments for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

drop policy "enrolments_update_own" on public.enrolments;
create policy "enrolments_update_own"
on public.enrolments for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

drop policy "enrolments_delete_own" on public.enrolments;
create policy "enrolments_delete_own"
on public.enrolments for delete
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session());

-- Programme consents ---------------------------------------------------------------

drop policy "programme_consents_insert_own" on public.programme_consents;
create policy "programme_consents_insert_own"
on public.programme_consents for insert
to authenticated
with check (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
      and e.status <> 'left'
  ) and public.deletion_barrier_open() and (
    programme_consents.purpose = 'core' or
    public.has_consent(programme_consents.enrolment_id, 'core')
  ) and
  not public.sync_writer_session()
);

drop policy "programme_consents_update_own" on public.programme_consents;
create policy "programme_consents_update_own"
on public.programme_consents for update
to authenticated
using (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
  ) and
  not public.sync_writer_session()
)
with check (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
  ) and
  not public.sync_writer_session()
);

-- Account consents -----------------------------------------------------------------

drop policy "account_consents_insert_own" on public.account_consents;
create policy "account_consents_insert_own"
on public.account_consents for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

drop policy "account_consents_update_own" on public.account_consents;
create policy "account_consents_update_own"
on public.account_consents for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

-- Functions that write, callable by authenticated -----------------------------------

create or replace function public.begin_account_deletion(p_confirmation text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH009',
      message = 'Account deletion goes through the API',
      hint = 'deletion_via_api_only';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;

  -- The update conflicts with avatar_write_allowed's row lock. Its committed
  -- timestamp is durable across API/storage failures and idempotent retries.
  update public.profiles
  set account_deletion_started_at = coalesce(account_deletion_started_at, now())
  where id = caller_id;
  return true;
end;
$$;

revoke all on function public.begin_account_deletion(text)
from public, anon, authenticated;
grant execute on function public.begin_account_deletion(text) to authenticated;

create or replace function public.save_program_data(
  p_program_id text,
  p_payload jsonb,
  p_revision integer
)
returns setof public.program_data
language plpgsql
security invoker
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  current_revision integer;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;

  -- Serialize writes per caller/program so out-of-order requests cannot win.
  perform pg_advisory_xact_lock(
    hashtextextended(caller_id::text || ':' || p_program_id, 0)
  );

  select revision into current_revision
  from public.program_data
  where user_id = caller_id and program_id = p_program_id;

  if current_revision is null then
    if p_revision <> 1 then
      return;
    end if;
    return query
      insert into public.program_data (user_id, program_id, payload, revision)
      values (caller_id, p_program_id, p_payload, p_revision)
      returning *;
    return;
  end if;

  if p_revision <> current_revision + 1 then
    return;
  end if;

  return query
    update public.program_data
    set payload = p_payload, revision = p_revision
    where user_id = caller_id and program_id = p_program_id
    returning *;
end;
$$;

revoke all on function public.save_program_data(text, jsonb, integer)
from public, anon, authenticated;
grant execute on function public.save_program_data(text, jsonb, integer)
to authenticated;

-- Account deletion. Unchanged except that the sync-session refusal now raises
-- TH009 (it raised insufficient_privilege with the same message).
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
  deleted_sync_areas integer := 0;
  deleted_sync_accounts integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH009',
      message = 'Account deletion goes through the API',
      hint = 'deletion_via_api_only';
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
  get diagnostics deleted_sync_areas = row_count;
  delete from public.sync_account where user_id = caller_id;
  get diagnostics deleted_sync_accounts = row_count;
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
    'sync_lapses', deleted_sync_lapses,
    'sync_areas', deleted_sync_areas,
    'sync_accounts', deleted_sync_accounts
  );
end;
$$;

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;
grant execute on function public.delete_my_app_data(text) to authenticated;

-- Error codes for the remaining custom errors ---------------------------------------

create or replace function public.enrolments_focus_cap()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  focus_count integer;
begin
  perform pg_advisory_xact_lock(
    hashtextextended('enrolments.focus:' || new.user_id::text, 0)
  );

  select count(*)
  into focus_count
  from public.enrolments
  where user_id = new.user_id and status = 'focus';

  if focus_count > 2 then
    raise exception using errcode = 'TH001',
      message = 'At most two programmes can be in focus',
      hint = 'focus_cap_reached';
  end if;
  return null;
end;
$$;

create or replace function public.consent_revoke_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise exception using errcode = 'TH002',
      message = 'Consent is already revoked',
      hint = 'consent_already_revoked';
  end if;
  if new.revoked_at is null then
    raise exception using errcode = 'TH003',
      message = 'Consent can only be revoked',
      hint = 'consent_immutable';
  end if;
  if (to_jsonb(new) - 'revoked_at') is distinct from
     (to_jsonb(old) - 'revoked_at') then
    raise exception using errcode = 'TH003',
      message = 'Consent records are immutable',
      hint = 'consent_immutable';
  end if;
  new.revoked_at = greatest(clock_timestamp(), old.granted_at);
  return new;
end;
$$;

create or replace function public.sync_area_match_enrolment()
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
    raise exception using errcode = 'TH007',
      message = 'Sync area must match its enrolment',
      hint = 'sync_area_mismatch';
  end if;
  return new;
end;
$$;

create or replace function public.sync_lapse_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH008',
    message = 'Lapses are append-only',
    hint = 'lapses_append_only';
end;
$$;

revoke all on function public.enrolments_focus_cap()
from public, anon, authenticated;
revoke all on function public.consent_revoke_only()
from public, anon, authenticated;
revoke all on function public.sync_area_match_enrolment()
from public, anon, authenticated;
revoke all on function public.sync_lapse_append_only()
from public, anon, authenticated;

commit;
