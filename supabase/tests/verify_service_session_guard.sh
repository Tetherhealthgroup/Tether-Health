#!/usr/bin/env bash
# Checks that the sync service session (thsync) writes only the sync tables,
# and that our custom database errors carry their registered SQLSTATE codes.
#
#   bash supabase/tests/verify_service_session_guard.sh       static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#       The SQL test switches the session user to thsync and to authenticator
#       (the PostgREST login role), so the URL's user must be a superuser.
#   bash <this script> --print-sql                     print the SQL test
#
# The SQL test uses synthetic identities only, runs in one transaction and
# always rolls back.
set -euo pipefail

migration="supabase/migrations/202610180002_service_session_guard.sql"
migrations_dir="supabase/migrations"
contract="docs/contracts/database.md"

print_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'FAIL setup: this SQL test needs a superuser connection (it switches the session user to thsync and authenticator)';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticator') then
    raise exception 'FAIL setup: role authenticator (the PostgREST login role) is missing';
  end if;
  if not (has_table_privilege('authenticated', 'storage.objects', 'SELECT')
          and has_table_privilege('authenticated', 'storage.objects', 'INSERT')
          and has_table_privilege('authenticated', 'storage.objects', 'UPDATE')
          and has_table_privilege('authenticated', 'storage.objects', 'DELETE')) then
    raise exception 'FAIL setup: authenticated needs table privileges on storage.objects (as in Supabase) for the avatar checks to mean anything';
  end if;
end;
$setup$;

select set_config('th972.superuser', session_user, true);

create schema th972_test;

create function th972_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with one of p_states and a message like p_message_like;
-- when p_hint is given, the error hint must equal it.
create function th972_test.refused(
  p_sql text, p_states text[], p_message_like text, p_label text,
  p_hint text default null
)
returns void language plpgsql set search_path = '' as $f$
declare
  got_hint text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics got_hint = pg_exception_hint;
    if sqlstate = any (p_states) and sqlerrm like p_message_like
       and (p_hint is null or got_hint is not distinct from p_hint) then
      raise notice 'PASS % (% %)%', p_label, sqlstate, sqlerrm,
        case when p_hint is null then '' else ' hint ' || got_hint end;
      return;
    end if;
    raise exception 'FAIL % (got % % hint %)', p_label, sqlstate, sqlerrm, got_hint;
  end;
  raise exception 'FAIL % (statement succeeded)', p_label;
end;
$f$;

create function th972_test.affects(p_sql text, p_rows integer, p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  n integer;
begin
  execute p_sql;
  get diagnostics n = row_count;
  if n is distinct from p_rows then
    raise exception 'FAIL % (% rows, expected %)', p_label, n, p_rows;
  end if;
  raise notice 'PASS % (% rows)', p_label, n;
end;
$f$;

-- Runs statements, then checks deferred constraints at once (the outer
-- transaction always rolls back, so commit-time checks would never fire).
create function th972_test.apply_now(p_sql text[])
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
begin
  foreach stmt in array p_sql loop
    execute stmt;
  end loop;
  set constraints public.enrolments_focus_cap immediate;
  set constraints public.enrolments_focus_cap deferred;
end;
$f$;

-- Switches the session to p_login acting as authenticated for p_sub, the way
-- the sync service (thsync) and PostgREST (authenticator) do; or back to the
-- superuser that started the test. No SET clause on purpose: SET LOCAL inside
-- a function with one would be undone when it returns.
create function th972_test.become(p_login text, p_sub text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('sub', p_sub, 'role', 'authenticated')::text, true);
  if p_login <> pg_catalog.current_setting('th972.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

grant usage on schema th972_test to public;
grant execute on all functions in schema th972_test to public;

-- Catalogue -------------------------------------------------------------------
-- Every insert/update policy outside sync_* checks the written row with
-- "not sync_writer_session()", and every delete policy checks it in using.
select th972_test.ok(
  not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public' and tablename !~ '^sync_'
      and cmd in ('INSERT', 'UPDATE')
      and coalesce(with_check, '') !~ 'NOT (public\.)?sync_writer_session\(\)')
  and not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public' and tablename !~ '^sync_'
      and cmd = 'DELETE'
      and coalesce(qual, '') !~ 'NOT (public\.)?sync_writer_session\(\)')
  and not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public' and tablename !~ '^sync_' and cmd = 'ALL'),
  'every public write policy outside sync_* refuses a sync session; no FOR ALL policies');
select th972_test.ok(
  not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname like 'avatars\_%'
      and ((cmd in ('INSERT', 'UPDATE')
            and coalesce(with_check, '') !~ 'NOT (public\.)?sync_writer_session\(\)')
        or (cmd = 'DELETE'
            and coalesce(qual, '') !~ 'NOT (public\.)?sync_writer_session\(\)')
        or cmd = 'ALL')),
  'every avatar write policy on storage.objects refuses a sync session');
select th972_test.ok(
  (select string_agg(schemaname || '.' || tablename || ':' || policyname, ','
     order by schemaname, tablename, policyname)
   from pg_catalog.pg_policies
   where ((schemaname = 'public' and tablename !~ '^sync_')
          or (schemaname = 'storage' and tablename = 'objects' and policyname like 'avatars\_%'))
     and cmd <> 'SELECT') =
  'public.account_consents:account_consents_insert_own,'
  'public.account_consents:account_consents_update_own,'
  'public.enrolments:enrolments_delete_own,public.enrolments:enrolments_insert_own,'
  'public.enrolments:enrolments_update_own,'
  'public.profiles:profiles_update_own,'
  'public.program_data:program_data_delete_own,public.program_data:program_data_insert_own,'
  'public.program_data:program_data_update_own,'
  'public.programme_consents:programme_consents_insert_own,'
  'public.programme_consents:programme_consents_update_own,'
  'public.quit_plans:quit_plans_insert_own,public.quit_plans:quit_plans_update_own,'
  'storage.objects:avatars_delete_own,storage.objects:avatars_insert_own,'
  'storage.objects:avatars_update_own',
  'the guarded write policies are exactly the 16 expected ones');
select th972_test.ok(
  not exists (
    select 1 from pg_catalog.pg_policies
    where ((schemaname = 'public' and tablename !~ '^sync_')
           or (schemaname = 'storage' and tablename = 'objects'))
      and cmd = 'SELECT' and coalesce(qual, '') ~ 'sync_writer_session')
  and (select coalesce(qual, '') !~ 'sync_writer_session' from pg_catalog.pg_policies
       where schemaname = 'public' and policyname = 'profiles_update_own'),
  'select policies, and the profile update using clause read by deletion_barrier_open, are unchanged for sync sessions');

-- Every function authenticated can execute in public is listed here, so a new
-- one has to be reviewed for the sync-session refusal before this passes.
select th972_test.ok(
  (select string_agg(p.oid::regprocedure::text, ',' order by p.oid::regprocedure::text)
   from pg_catalog.pg_proc as p
   where p.pronamespace = 'public'::regnamespace
     and has_function_privilege('authenticated', p.oid, 'EXECUTE')) =
  'avatar_write_allowed(text),begin_account_deletion(text),delete_my_app_data(text),'
  'deletion_barrier_open(),has_consent(uuid,text,text),is_unique_text_array(text[]),'
  'is_valid_support_people(jsonb),save_program_data(text,jsonb,integer),sync_writer_session()',
  'functions authenticated can execute are exactly the reviewed set');
select th972_test.ok(
  (select bool_and(prosecdef = (proname <> 'save_program_data')
                   and proconfig = array['search_path=""'])
   from pg_catalog.pg_proc
   where oid in ('public.begin_account_deletion(text)'::regprocedure,
                 'public.delete_my_app_data(text)'::regprocedure,
                 'public.save_program_data(text,jsonb,integer)'::regprocedure)),
  'deletion functions stay security definer, save_program_data invoker; search_path empty');
select th972_test.ok(
  not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
    where p.oid in ('public.begin_account_deletion(text)'::regprocedure,
                    'public.delete_my_app_data(text)'::regprocedure,
                    'public.save_program_data(text,jsonb,integer)'::regprocedure,
                    'public.enrolments_focus_cap()'::regprocedure,
                    'public.consent_revoke_only()'::regprocedure,
                    'public.sync_area_match_enrolment()'::regprocedure,
                    'public.sync_lapse_append_only()'::regprocedure)
      and (a.grantee = 0 or a.grantee in ('anon'::regrole, 'thsync'::regrole))),
  'changed functions: no execute for anon, thsync or PUBLIC');

-- Synthetic identity only.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-000000972002', 'synthetic-user-02@example.test',
   'authenticated', 'authenticated');
select th972_test.ok(
  (select count(*) from public.profiles
   where id = '00000000-0000-4000-8000-000000972002') = 1,
  'setup: the signup trigger created the synthetic profile');

-- B through the API (PostgREST stand-in): set up rows -------------------------
select th972_test.become('authenticator', '00000000-0000-4000-8000-000000972002');
with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000972002', 'hw') returning id
) select set_config('th972.b_hw', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, mode)
  values ('00000000-0000-4000-8000-000000972002', 'bf', 'quit') returning id
) select set_config('th972.b_bf', id::text, true) from i;
select th972_test.affects(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''core'', ''v1'', ''Synthetic core wording'')',
  current_setting('th972.b_hw')), 1, 'B API: grants core consent on Heartwise');
select th972_test.affects(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''research'', ''v1'', ''Synthetic research wording'')',
  current_setting('th972.b_hw')), 1, 'B API: grants research consent on Heartwise');
select th972_test.affects(
  'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
   values (''00000000-0000-4000-8000-000000972002'', ''essential'', ''v1'', ''Synthetic essential wording'')',
  1, 'B API: grants an account consent');
select th972_test.affects(
  'update public.profiles set display_name = ''Synthetic Member''',
  1, 'B API: updates the profile');
-- The first save returns the stored row (an existing quirk returns it twice);
-- the stored state is checked below.
select th972_test.ok(
  (select count(*) >= 1 and bool_and(revision = 1)
   from public.save_program_data('heartwise', '{"step":1}'::jsonb, 1)),
  'B API: saves program data through save_program_data');
select th972_test.affects(
  'insert into storage.objects (bucket_id, name)
   values (''avatars'', ''00000000-0000-4000-8000-000000972002/avatar.png'')',
  1, 'B API: uploads an avatar object');

-- B through the sync service: sync writes and reads still work ----------------
select th972_test.become('thsync', '00000000-0000-4000-8000-000000972002');
select th972_test.ok(session_user = 'thsync' and current_user = 'authenticated'
  and auth.uid() = '00000000-0000-4000-8000-000000972002'
  and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with B''s claims');
select th972_test.ok(
  public.has_consent(current_setting('th972.b_hw')::uuid, 'core')
  and public.has_consent(current_setting('th972.b_hw')::uuid, 'research')
  and public.deletion_barrier_open(),
  'B sync: has_consent and deletion_barrier_open still read what they need');
select th972_test.ok(
  (select count(*) from public.enrolments) = 2
  and (select count(*) from public.programme_consents) = 2
  and (select count(*) from public.profiles) = 1,
  'B sync: still reads B''s enrolments, consents and profile');
select th972_test.affects(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000972002'')',
  1, 'B sync: creates the sync account');
select th972_test.affects(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000972002'', %L, ''hw'', 1, 1)',
  current_setting('th972.b_hw')), 1, 'B sync: creates the Heartwise area');
select th972_test.affects(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000972002'', ''hw'', ''hw_targets'', ''{"slider":{"0":120}}'')',
  1, 'B sync: stores an answer');
select th972_test.affects(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000972002'', ''hw'', 0, now())',
  1, 'B sync: appends a lapse');
select th972_test.affects(
  'update public.sync_answer set payload = ''{"slider":{"0":125}}'' where screen_id = ''hw_targets''',
  1, 'B sync: updates the answer');
select th972_test.affects(
  'update public.sync_area set revision = 2, change_seq = 2 where programme_code = ''hw''',
  1, 'B sync: bumps the area revision');
select th972_test.affects('update public.sync_account set change_seq = 2',
  1, 'B sync: bumps the change counter');

-- B through the sync service: every other write is refused --------------------
select th972_test.refused(
  'insert into public.enrolments (user_id, programme_code, status)
   values (''00000000-0000-4000-8000-000000972002'', ''st'', ''learn_only'')',
  array['42501'], '%row-level security%', 'B sync: cannot insert an enrolment');
select th972_test.refused(format(
  'update public.enrolments set status = ''paused'' where id = %L',
  current_setting('th972.b_hw')),
  array['42501'], '%row-level security%', 'B sync: cannot update an enrolment');
select th972_test.affects(format(
  'delete from public.enrolments where id = %L', current_setting('th972.b_bf')),
  0, 'B sync: cannot delete an enrolment (no row qualifies)');
select th972_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''reminders'', ''v1'', ''Synthetic reminder wording'')',
  current_setting('th972.b_hw')),
  array['42501'], '%row-level security%', 'B sync: cannot grant a programme consent');
select th972_test.refused(format(
  'update public.programme_consents set revoked_at = now()
   where enrolment_id = %L and purpose = ''research''',
  current_setting('th972.b_hw')),
  array['42501'], '%row-level security%', 'B sync: cannot revoke a programme consent');
select th972_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
   values (''00000000-0000-4000-8000-000000972002'', ''diagnostics'', ''v1'', ''Synthetic'')',
  array['42501'], '%row-level security%', 'B sync: cannot grant an account consent');
select th972_test.refused(
  'update public.account_consents set revoked_at = now() where purpose = ''essential''',
  array['42501'], '%row-level security%', 'B sync: cannot revoke an account consent');
select th972_test.refused(
  'update public.profiles set display_name = ''Changed by sync''',
  array['42501'], '%row-level security%', 'B sync: cannot update the profile');
select th972_test.refused(
  'insert into public.quit_plans (user_id, quit_date)
   values (''00000000-0000-4000-8000-000000972002'', current_date)',
  array['42501'], '%row-level security%', 'B sync: cannot insert a quit plan');
select th972_test.refused(
  'insert into public.program_data (user_id, program_id, payload)
   values (''00000000-0000-4000-8000-000000972002'', ''steady'', ''{}'')',
  array['42501'], '%row-level security%', 'B sync: cannot insert program data');
select th972_test.refused(
  'update public.program_data set payload = ''{}'' where program_id = ''heartwise''',
  array['42501'], '%row-level security%', 'B sync: cannot update program data');
select th972_test.affects('delete from public.program_data',
  0, 'B sync: cannot delete program data (no row qualifies)');
select th972_test.refused(
  'select * from public.save_program_data(''heartwise'', ''{"step":2}''::jsonb, 2)',
  array['TH010'], 'The sync service writes only sync tables',
  'B sync: save_program_data refuses the sync session', 'sync_session_refused');
select th972_test.refused(
  'insert into storage.objects (bucket_id, name)
   values (''avatars'', ''00000000-0000-4000-8000-000000972002/sync.png'')',
  array['42501'], '%row-level security%', 'B sync: cannot upload an avatar object');
select th972_test.refused(
  'update storage.objects set name = ''00000000-0000-4000-8000-000000972002/moved.png''
   where name = ''00000000-0000-4000-8000-000000972002/avatar.png''',
  array['42501'], '%row-level security%', 'B sync: cannot update an avatar object');
select th972_test.affects(
  'delete from storage.objects where bucket_id = ''avatars''',
  0, 'B sync: cannot delete an avatar object (no row qualifies)');
select th972_test.refused('select public.begin_account_deletion(''DELETE'')',
  array['TH009'], 'Account deletion goes through the API',
  'B sync: begin_account_deletion refuses the sync session', 'deletion_via_api_only');
select th972_test.refused('select public.delete_my_app_data(''DELETE'')',
  array['TH009'], 'Account deletion goes through the API',
  'B sync: delete_my_app_data refuses the sync session', 'deletion_via_api_only');
select th972_test.refused(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000972002'', %L, ''st'', 1, 3)',
  current_setting('th972.b_bf')),
  array['TH007'], 'Sync area must match its enrolment',
  'B sync: an area that does not match its enrolment raises TH007', 'sync_area_mismatch');

-- Nothing outside the sync tables changed -------------------------------------
select th972_test.become(current_setting('th972.superuser'), '');
select th972_test.ok(
  (select count(*) from public.enrolments
   where user_id = '00000000-0000-4000-8000-000000972002' and status = 'focus') = 2
  and (select count(*) from public.enrolments
       where user_id = '00000000-0000-4000-8000-000000972002') = 2
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th972.b_hw')::uuid and revoked_at is null) = 2
  and (select count(*) from public.programme_consents
       where enrolment_id in (current_setting('th972.b_hw')::uuid,
                              current_setting('th972.b_bf')::uuid)) = 2
  and (select count(*) from public.account_consents
       where user_id = '00000000-0000-4000-8000-000000972002' and revoked_at is null) = 1
  and (select count(*) from public.account_consents
       where user_id = '00000000-0000-4000-8000-000000972002') = 1
  and (select display_name = 'Synthetic Member' and account_deletion_started_at is null
       from public.profiles where id = '00000000-0000-4000-8000-000000972002')
  and (select count(*) from public.quit_plans
       where user_id = '00000000-0000-4000-8000-000000972002') = 0
  and (select string_agg(program_id || ':' || revision || ':' || payload::text, ',')
       from public.program_data
       where user_id = '00000000-0000-4000-8000-000000972002') = 'heartwise:1:{"step": 1}'
  and (select string_agg(name, ',') from storage.objects where bucket_id = 'avatars'
       and name like '00000000-0000-4000-8000-000000972002/%')
      = '00000000-0000-4000-8000-000000972002/avatar.png',
  'the refused sync-session writes left enrolments, consents, profile, quit plan, program data and avatars unchanged');
select th972_test.ok(
  (select count(*) from public.sync_account
   where user_id = '00000000-0000-4000-8000-000000972002' and change_seq = 2) = 1
  and (select count(*) from public.sync_area
       where user_id = '00000000-0000-4000-8000-000000972002' and revision = 2) = 1
  and (select count(*) from public.sync_answer
       where user_id = '00000000-0000-4000-8000-000000972002') = 1
  and (select count(*) from public.sync_lapse
       where user_id = '00000000-0000-4000-8000-000000972002') = 1,
  'the sync-session writes to sync tables were stored');
select th972_test.refused('update public.sync_lapse set severity = ''changed''',
  array['TH008'], 'Lapses are append-only',
  'superuser: a lapse update raises TH008', 'lapses_append_only');
select th972_test.refused(format(
  'update public.programme_consents set consent_text = ''changed'', revoked_at = now()
   where enrolment_id = %L and purpose = ''research''',
  current_setting('th972.b_hw')),
  array['TH003'], 'Consent records are immutable',
  'superuser: rewriting consent wording raises TH003', 'consent_immutable');

-- B through the API: everything it could do before still works ---------------
select th972_test.become('authenticator', '00000000-0000-4000-8000-000000972002');
select th972_test.ok(not public.sync_writer_session(),
  'API session: sync_writer_session() is false');
select th972_test.affects(
  'insert into public.quit_plans (user_id, quit_date)
   values (''00000000-0000-4000-8000-000000972002'', current_date)',
  1, 'B API: inserts a quit plan');
select th972_test.affects(
  'update public.quit_plans set quit_day_check_in = false',
  1, 'B API: updates the quit plan');
select th972_test.ok(
  (select count(*) = 1 and min(revision) = 2
   from public.save_program_data('heartwise', '{"step":2}'::jsonb, 2)),
  'B API: save_program_data still saves the next revision');
select th972_test.affects(
  'insert into public.program_data (user_id, program_id, payload)
   values (''00000000-0000-4000-8000-000000972002'', ''steady'', ''{}'')',
  1, 'B API: inserts program data directly');
select th972_test.affects(
  'update public.program_data set payload = ''{"a":1}'' where program_id = ''steady''',
  1, 'B API: updates program data directly');
select th972_test.affects(
  'delete from public.program_data where program_id = ''steady''',
  1, 'B API: deletes program data directly');
select th972_test.affects(format(
  'update public.enrolments set status = ''learn_only'' where id = %L',
  current_setting('th972.b_bf')), 1, 'B API: updates an enrolment');
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-000000972002', 'ca', 'learn_only') returning id
) select set_config('th972.b_ca', id::text, true) from i;
select th972_test.affects(format(
  'delete from public.enrolments where id = %L', current_setting('th972.b_ca')),
  1, 'B API: inserts and deletes an enrolment');
select th972_test.affects(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''reminders'', ''v1'', ''Synthetic reminder wording'')',
  current_setting('th972.b_hw')), 1, 'B API: grants a programme consent');
select th972_test.affects(format(
  'update public.programme_consents set revoked_at = now()
   where enrolment_id = %L and purpose = ''reminders''',
  current_setting('th972.b_hw')), 1, 'B API: revokes a programme consent');
select th972_test.affects(
  'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
   values (''00000000-0000-4000-8000-000000972002'', ''diagnostics'', ''v1'', ''Synthetic'')',
  1, 'B API: grants an account consent');
select th972_test.affects(
  'update public.account_consents set revoked_at = now() where purpose = ''diagnostics''',
  1, 'B API: revokes an account consent');
select th972_test.affects(
  'update public.profiles set locale = ''es''', 1, 'B API: updates the profile');
select th972_test.affects(
  'update storage.objects set name = ''00000000-0000-4000-8000-000000972002/avatar.png''
   where name = ''00000000-0000-4000-8000-000000972002/avatar.png''',
  1, 'B API: updates the avatar object');
select th972_test.affects(
  'insert into storage.objects (bucket_id, name)
   values (''avatars'', ''00000000-0000-4000-8000-000000972002/second.png'')',
  1, 'B API: uploads another avatar object');
select th972_test.affects(
  'delete from storage.objects
   where name = ''00000000-0000-4000-8000-000000972002/second.png''',
  1, 'B API: deletes an avatar object');

-- Error codes on the API path --------------------------------------------------
select th972_test.refused(format(
  'select th972_test.apply_now(array[%L, %L])',
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000972002'', ''st'')',
  format('update public.enrolments set status = ''focus'' where id = %L',
    current_setting('th972.b_bf'))),
  array['TH001'], 'At most two programmes can be in focus',
  'B API: a third programme in focus raises TH001', 'focus_cap_reached');
select th972_test.refused(format(
  'update public.programme_consents set revoked_at = null
   where enrolment_id = %L and purpose = ''reminders''',
  current_setting('th972.b_hw')),
  array['TH002'], 'Consent is already revoked',
  'B API: un-revoking a consent raises TH002', 'consent_already_revoked');
select th972_test.refused(format(
  'update public.programme_consents set revoked_at = null
   where enrolment_id = %L and purpose = ''research''',
  current_setting('th972.b_hw')),
  array['TH003'], 'Consent can only be revoked',
  'B API: an update that does not revoke raises TH003', 'consent_immutable');

-- Account deletion through the API still works --------------------------------
select th972_test.become(current_setting('th972.superuser'), '');
select set_config('th972.b_counts', jsonb_build_object(
  'profiles', 1,
  'quit_plans', (select count(*) from public.quit_plans
                 where user_id = '00000000-0000-4000-8000-000000972002'),
  'program_data', (select count(*) from public.program_data
                   where user_id = '00000000-0000-4000-8000-000000972002'),
  'enrolments', (select count(*) from public.enrolments
                 where user_id = '00000000-0000-4000-8000-000000972002'),
  'programme_consents', (select count(*) from public.programme_consents c
                         join public.enrolments e on e.id = c.enrolment_id
                         where e.user_id = '00000000-0000-4000-8000-000000972002'),
  'account_consents', (select count(*) from public.account_consents
                       where user_id = '00000000-0000-4000-8000-000000972002'),
  'sync_answers', (select count(*) from public.sync_answer
                   where user_id = '00000000-0000-4000-8000-000000972002'),
  'sync_lapses', (select count(*) from public.sync_lapse
                  where user_id = '00000000-0000-4000-8000-000000972002'),
  'sync_areas', (select count(*) from public.sync_area
                 where user_id = '00000000-0000-4000-8000-000000972002'),
  'sync_accounts', (select count(*) from public.sync_account
                    where user_id = '00000000-0000-4000-8000-000000972002')
)::text, true);
select th972_test.ok(
  current_setting('th972.b_counts')::jsonb = '{"profiles": 1, "quit_plans": 1,
    "program_data": 1, "enrolments": 2, "programme_consents": 3, "account_consents": 2,
    "sync_answers": 1, "sync_lapses": 1, "sync_areas": 1, "sync_accounts": 1}'::jsonb,
  'B has the expected rows before deletion');
select th972_test.become('authenticator', '00000000-0000-4000-8000-000000972002');
select th972_test.ok(public.begin_account_deletion('DELETE'),
  'B API: begin_account_deletion still sets the barrier');
select th972_test.become('thsync', '00000000-0000-4000-8000-000000972002');
select th972_test.refused('select public.delete_my_app_data(''DELETE'')',
  array['TH009'], 'Account deletion goes through the API',
  'B sync: delete_my_app_data still refuses the sync session after the barrier', 'deletion_via_api_only');
select th972_test.become('authenticator', '00000000-0000-4000-8000-000000972002');
select set_config('th972.b_receipt', public.delete_my_app_data('DELETE')::text, true);
select th972_test.ok(
  current_setting('th972.b_receipt')::jsonb = current_setting('th972.b_counts')::jsonb,
  'B API: delete_my_app_data still deletes everything and returns the counts');
select th972_test.become(current_setting('th972.superuser'), '');
select th972_test.ok(
  (select count(*) from public.profiles
   where id = '00000000-0000-4000-8000-000000972002') = 0
  and (select count(*) from public.enrolments
       where user_id = '00000000-0000-4000-8000-000000972002') = 0
  and (select count(*) from public.sync_account
       where user_id = '00000000-0000-4000-8000-000000972002') = 0,
  'deletion removed B''s profile, enrolments and sync rows');

select 'TH972A_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Service-session guard check failed: $1" >&2
  exit 1
}

# Accepts only postgres:// or postgresql:// URLs whose whole authority is
# [userinfo@]127.0.0.1|localhost[:port]: one '@' at most, no comma host lists,
# and no query string, fragment or whitespace anywhere (libpq parameters such
# as host= could redirect the connection).
url_shape='^postgres(ql)?://([^/]*)(/[^?#[:space:]]*)?$'
local_authority='^([^@/?#,[:space:]]*@)?(127\.0\.0\.1|localhost)(:[0-9]{1,5})?$'
db_url_is_local() {
  [[ "$1" =~ $url_shape ]] || return 1
  [[ "${BASH_REMATCH[2]}" =~ $local_authority ]]
}

# Self-test of the guard; runs with the static checks.
for u in 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' \
  'postgres://postgres@localhost:54322/postgres' 'postgresql://localhost/postgres'; do
  db_url_is_local "$u" || fail "local URL guard rejects a local URL ($u)"
done
for u in 'postgresql://postgres:postgres@db.example.test:5432/postgres' \
  'postgresql://postgres@127.0.0.1.example.test:5432/postgres' \
  'postgresql://postgres@localhost:54322/postgres?host=db.example.test' \
  'postgresql://postgres@localhost,db.example.test:5432/postgres' \
  'postgresql:///postgres' 'host=localhost dbname=postgres' \
  'postgresql://user@db.example.test/x@127.0.0.1' \
  'postgresql://u:p@ss@127.0.0.1/postgres' \
  'postgresql://u@db.example.test:5432@127.0.0.1/postgres' \
  'postgresql://u@db.example.test:5432@localhost:54322/postgres' \
  'postgresql://postgres@localhost:54322/postgres#db.example.test' \
  'postgresql://postgres@localhost#@db.example.test/postgres' \
  'postgresql://postgres@localhost:54322/post gres' \
  'postgresql://post gres@localhost:54322/postgres' \
  'postgresql://postgres@[::1]:54322/postgres' \
  'postgresql://postgres@localhost:543221/postgres'; do
  if db_url_is_local "$u"; then fail "local URL guard accepts a non-local URL ($u)"; fi
done

if [[ -n "${VERIFY_DB_URL:-}" ]] && ! db_url_is_local "$VERIFY_DB_URL"; then
  fail 'VERIFY_DB_URL must point at a local database (127.0.0.1 or localhost)'
fi

[[ -f "$migration" ]] || fail "missing $migration"
[[ -f "$contract" ]] || fail "missing $contract"
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

migration_files=()
while IFS= read -r -d '' path; do
  migration_files+=("$path")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -name '*.sql' -print0 | LC_ALL=C sort -z)

# Final write policies, across all migrations in apply order -------------------
# Prints "<table> <name> <command> <guard-in-using> <guard-in-check>" for every
# policy that still exists after the last migration ("drop policy" removes one).
final_policies() {
  awk '
    function flush() {
      if (buf == "") return
      name = buf; sub(/^create policy "/, "", name); sub(/".*/, "", name)
      tbl = ""
      if (match(buf, / on [a-z_]+\.[a-z_]+ /)) tbl = substr(buf, RSTART + 4, RLENGTH - 5)
      cmd = "all"
      if (match(buf, / for (select|insert|update|delete|all) /)) cmd = substr(buf, RSTART + 5, RLENGTH - 6)
      using = buf; check = ""
      if (index(buf, " with check ")) {
        using = substr(buf, 1, index(buf, " with check ") - 1)
        check = substr(buf, index(buf, " with check "))
      }
      g = "not public.sync_writer_session()"
      key = tbl " " name
      def[key] = cmd " " (index(using, g) ? 1 : 0) " " (index(check, g) ? 1 : 0)
      buf = ""
    }
    /^create policy "/ { buf = $0; grab = 1; if ($0 ~ /;$/) { grab = 0; flush() }; next }
    grab { buf = buf " " $0; if ($0 ~ /;$/) { grab = 0; flush() }; next }
    /^drop policy "/ {
      n = $0; sub(/^drop policy "/, "", n); sub(/".*/, "", n)
      t = ""
      if (match($0, / on [a-z_]+\.[a-z_]+;/)) t = substr($0, RSTART + 4, RLENGTH - 5)
      delete def[t " " n]
    }
    END { for (k in def) print k, def[k] }
  ' "${migration_files[@]}" | LC_ALL=C sort
}

policies=$(final_policies)
guarded=()
while read -r tbl name cmd in_using in_check; do
  [[ -n "$tbl" ]] || continue
  case "$tbl" in
    public.sync_*) continue ;;
    public.*) ;;
    storage.objects) [[ "$name" == avatars_* ]] || continue ;;
    *) continue ;;
  esac
  case "$cmd" in
    select) continue ;;
    insert|update) [[ "$in_check" == 1 ]] || fail "$tbl $name: with check must include 'not public.sync_writer_session()'" ;;
    delete) [[ "$in_using" == 1 ]] || fail "$tbl $name: using must include 'not public.sync_writer_session()'" ;;
    *) fail "$tbl $name: use per-command policies (for $cmd), so sync sessions can keep reading" ;;
  esac
  guarded+=("$tbl:$name")
done <<<"$policies"
for expected in public.profiles:profiles_update_own \
  public.quit_plans:quit_plans_insert_own public.quit_plans:quit_plans_update_own \
  public.program_data:program_data_insert_own public.program_data:program_data_update_own \
  public.program_data:program_data_delete_own \
  public.enrolments:enrolments_insert_own public.enrolments:enrolments_update_own \
  public.enrolments:enrolments_delete_own \
  public.programme_consents:programme_consents_insert_own \
  public.programme_consents:programme_consents_update_own \
  public.account_consents:account_consents_insert_own \
  public.account_consents:account_consents_update_own \
  storage.objects:avatars_insert_own storage.objects:avatars_update_own \
  storage.objects:avatars_delete_own; do
  printf '%s\n' "${guarded[@]}" | grep -Fxq "$expected" || fail "missing guarded write policy $expected"
done
# deletion_barrier_open() reads the profile FOR SHARE, which applies the update
# policy's using clause; a guard there would stop every sync write.
grep -Eq '^public\.profiles profiles_update_own update 0 1$' <<<"$policies" ||
  fail 'profiles_update_own: guard belongs in with check only (its using clause is read by deletion_barrier_open)'

# Latest definition of each function ------------------------------------------
latest_body() {
  local fn="$1" file
  file=$(grep -El "^create (or replace )?function public\\.$fn\\(" "${migration_files[@]}" | tail -n 1)
  [[ -n "$file" ]] || fail "no definition of public.$fn"
  sed -n "/^create \\(or replace \\)\\{0,1\\}function public\\.$fn(/,/^\\\$\\\$;/p" "$file"
}

sync_refusal() {
  local fn="$1" code="$2" body
  body=$(latest_body "$fn")
  grep -Eq "^  if public\\.sync_writer_session\\(\\) then$" <<<"$body" ||
    fail "$fn must refuse a sync session"
  grep -A1 '^  if public\.sync_writer_session() then$' <<<"$body" |
    grep -Eq "raise exception using errcode = '$code'," || fail "$fn must raise $code for a sync session"
}
sync_refusal begin_account_deletion TH009
sync_refusal delete_my_app_data TH009
sync_refusal save_program_data TH010

for pair in enrolments_focus_cap:TH001 consent_revoke_only:TH002 consent_revoke_only:TH003 \
  sync_area_match_enrolment:TH007 sync_lapse_append_only:TH008; do
  fn="${pair%%:*}"
  code="${pair##*:}"
  body=$(latest_body "$fn")
  grep -Eq "errcode = '$code'," <<<"$body" || fail "$fn must raise $code"
  if grep -Eq 'raise (check_violation|insufficient_privilege)' <<<"$body"; then
    fail "$fn still raises a generic SQLSTATE"
  fi
done

# Registry: every TH code raised in a migration is in the contract with the
# same snake_case name, and every raise carries that name as its hint.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry=$(sed -nE 's/^\| `(TH[0-9]{3})` \| `([a-z_]+)` \|.*/\1 \2/p' "$contract")
[[ -n "$registry" ]] || fail "no SQLSTATE registry rows in $contract"
[[ "$(cut -d' ' -f1 <<<"$registry" | sort | uniq -d)" == '' ]] || fail 'registry codes must be unique'
[[ "$(cut -d' ' -f2 <<<"$registry" | sort | uniq -d)" == '' ]] || fail 'registry names must be unique'
for code in TH001 TH002 TH003 TH004 TH005 TH006 TH007 TH008 TH009 TH010; do
  grep -Eq "^$code " <<<"$registry" || fail "registry is missing $code"
done
raises=$(awk '
  /errcode = .TH[0-9][0-9][0-9]./ { code = $0; sub(/.*errcode = ./, "", code); code = substr(code, 1, 5); next }
  code != "" && /hint = ./ { h = $0; sub(/.*hint = ./, "", h); sub(/.;?$/, "", h); print code, h; code = "" }
' "${migration_files[@]}" | sort -u)
[[ -n "$raises" ]] || fail 'no TH errors raised in migrations'
while read -r code hint; do
  grep -Fxq "$code $hint" <<<"$registry" || fail "$code is raised with hint '$hint', which does not match the registry"
done <<<"$raises"
[[ "$(grep -Ec "errcode = 'TH[0-9]{3}'" "$migration")" -eq "$(grep -Ec "^ +hint = '[a-z_]+';?$" "$migration")" ]] ||
  fail 'every TH raise needs a hint'

# Never loosen ----------------------------------------------------------------
functions=$(grep -Ec '^create (or replace )?function ' "$migration")
pinned=$(grep -Ec "^set search_path = ''$" "$migration")
[[ "$functions" -eq "$pinned" ]] || fail "$functions functions but $pinned with search_path = ''"
[[ "$(grep -Ec '^security definer$' "$migration")" -eq 2 ]] ||
  fail 'only begin_account_deletion and delete_my_app_data may be security definer'
if grep -Eiq 'disable row level security|no force row level security|bypassrls|security_barrier *= *false' "$migration"; then
  fail 'migration must not disable or bypass RLS'
fi
if grep -Eiq '(create|alter|drop) role|to thsync|owner to' "$migration"; then
  fail 'migration must not change roles or grant anything to thsync'
fi
if grep -Eiq 'grant .* to (.*[^a-z_])?anon([^a-z_]|$)' "$migration"; then
  fail 'nothing is granted to anon'
fi
if grep -Eiq 'grant all|^grant (select|insert|update|delete)' "$migration"; then
  fail 'no table grants change in this migration'
fi
if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  fail 'migration must not contain credentials or service-role use'
fi
if grep -Eiq '^create policy "sync_|^drop policy "sync_' "$migration"; then
  fail 'sync table policies are not changed here'
fi

echo 'Service-session guard static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH972A_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  echo 'Service-session guard SQL test passed.'
fi
