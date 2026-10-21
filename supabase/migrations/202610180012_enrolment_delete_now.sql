begin;

-- "Delete now" for one programme goes through one function; members can no
-- longer delete enrolments directly, and no enrolment changes once account
-- deletion has started.
--
-- * The enrolment delete policy is dropped and DELETE on public.enrolments is
--   revoked from PUBLIC, anon and authenticated. With row-level security
--   forced and no delete policy, a later grant alone would not reopen the
--   direct path.
-- * The enrolment update policy's with check also requires the deletion
--   barrier to be open, so leaving, rejoining, pausing, a mode change and a
--   focus swap are refused once account deletion has started or the profile
--   is gone. Its using clause is unchanged.
-- * public.delete_enrolment_now(p_enrolment_id, p_confirmation) deletes one of
--   the caller's enrolments and that programme's data, children first: care
--   share access rows, care messages, care shares, caregiver events,
--   caregivers, sync lapses, answers and area, programme consents, the quit
--   plan (BreatheFree only), the program data snapshot (Heartwise, Steady and
--   ClearAir only) and the enrolment. Every delete is limited to the caller's
--   rows. It returns one count per table, nothing else. It refuses, in this
--   order: no caller (42501); a sync service session (TH010); a confirmation
--   other than 'DELETE' (23514); a sign-in that is not recent (TH017), by the
--   same rule as account deletion; a function owner that neither is a
--   superuser nor bypasses row-level security (TH020); an enrolment that does
--   not exist or is not the caller's (TH012). It does not check the deletion
--   barrier: deleting data stays allowed after account deletion has started.
--   Any refusal deletes nothing. The enrolment row is locked first, so a
--   second call for the same enrolment finds nothing (TH012).
-- * Connections, supporters (they only lose the programme's code), account
--   consents, messages not tied to the programme and the profile are account
--   data and are kept.
-- * Only authenticated may execute it.

drop policy "enrolments_delete_own" on public.enrolments;

revoke delete on table public.enrolments from public, anon, authenticated;

drop policy "enrolments_update_own" on public.enrolments;
create policy "enrolments_update_own"
on public.enrolments for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create function public.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  newest_sign_in numeric;
  sign_in_age numeric;
  v_programme_code text;
  deleted_quit_plans integer := 0;
  deleted_program_data integer := 0;
  deleted_enrolments integer := 0;
  deleted_programme_consents integer := 0;
  deleted_sync_answers integer := 0;
  deleted_sync_lapses integer := 0;
  deleted_sync_areas integer := 0;
  deleted_care_share_access integer := 0;
  deleted_care_messages integer := 0;
  deleted_care_shares integer := 0;
  deleted_caregiver_events integer := 0;
  deleted_caregivers integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;

  -- Recent sign-in: the newest amr entry with a string method and a numeric
  -- timestamp (seconds since the epoch). Anything else counts as missing.
  select max((m.entry ->> 'timestamp')::numeric)
  into newest_sign_in
  from jsonb_array_elements(
    case when jsonb_typeof(auth.jwt() -> 'amr') = 'array'
         then auth.jwt() -> 'amr' else '[]'::jsonb end
  ) as m(entry)
  where jsonb_typeof(m.entry) = 'object'
    and jsonb_typeof(m.entry -> 'method') = 'string'
    and jsonb_typeof(m.entry -> 'timestamp') = 'number';
  sign_in_age := extract(epoch from now()) - newest_sign_in;
  if sign_in_age is null or sign_in_age > 600 or sign_in_age < -60 then
    raise exception using errcode = 'TH017',
      message = 'Recent authentication is required',
      hint = 'recent_authentication_required';
  end if;

  -- The checks and deletes below run as the function owner and must see
  -- every row: the owner has to bypass row-level security.
  if not exists (
    select 1 from pg_catalog.pg_roles as r
    where r.rolname = current_user and (r.rolsuper or r.rolbypassrls)
  ) then
    raise exception using errcode = 'TH020',
      message = 'Account deletion requires a function owner that bypasses row-level security',
      hint = 'rls_bypass_required';
  end if;

  select e.programme_code
  into v_programme_code
  from public.enrolments as e
  where e.id = p_enrolment_id
    and e.user_id = caller_id
  for update;
  if not found then
    raise exception using errcode = 'TH012',
      message = 'Enrolment not found',
      hint = 'enrolment_not_found';
  end if;

  delete from public.care_share_access
  where user_id = caller_id
    and share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id);
  get diagnostics deleted_care_share_access = row_count;
  delete from public.care_messages
  where user_id = caller_id
    and (enrolment_id = p_enrolment_id
         or share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id));
  get diagnostics deleted_care_messages = row_count;
  delete from public.care_shares
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_care_shares = row_count;
  delete from public.caregiver_events
  where user_id = caller_id
    and caregiver_id in (select id from public.caregivers where enrolment_id = p_enrolment_id);
  get diagnostics deleted_caregiver_events = row_count;
  delete from public.caregivers
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_caregivers = row_count;
  delete from public.sync_lapse
  where user_id = caller_id and programme_code = v_programme_code;
  get diagnostics deleted_sync_lapses = row_count;
  delete from public.sync_answer
  where user_id = caller_id and programme_code = v_programme_code;
  get diagnostics deleted_sync_answers = row_count;
  delete from public.sync_area
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_sync_areas = row_count;
  delete from public.programme_consents
  where enrolment_id = p_enrolment_id
    and enrolment_id in (select id from public.enrolments where user_id = caller_id);
  get diagnostics deleted_programme_consents = row_count;
  if v_programme_code = 'bf' then
    delete from public.quit_plans where user_id = caller_id;
    get diagnostics deleted_quit_plans = row_count;
  end if;
  delete from public.program_data
  where user_id = caller_id
    and program_id = (select p.slug from public.programmes as p where p.code = v_programme_code);
  get diagnostics deleted_program_data = row_count;
  delete from public.enrolments
  where user_id = caller_id and id = p_enrolment_id;
  get diagnostics deleted_enrolments = row_count;

  return jsonb_build_object(
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data,
    'enrolments', deleted_enrolments,
    'programme_consents', deleted_programme_consents,
    'sync_answers', deleted_sync_answers,
    'sync_lapses', deleted_sync_lapses,
    'sync_areas', deleted_sync_areas,
    'care_share_access', deleted_care_share_access,
    'care_messages', deleted_care_messages,
    'care_shares', deleted_care_shares,
    'caregiver_events', deleted_caregiver_events,
    'caregivers', deleted_caregivers
  );
end;
$$;

revoke all on function public.delete_enrolment_now(uuid, text)
from public, anon, authenticated, service_role;
grant execute on function public.delete_enrolment_now(uuid, text) to authenticated;

commit;
