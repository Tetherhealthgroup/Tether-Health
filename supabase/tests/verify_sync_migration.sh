#!/usr/bin/env bash
# Checks for the sync tables migration (sync_account, sync_area, sync_answer,
# sync_lapse and the thsync role).
#
#   bash supabase/tests/verify_sync_migration.sh            static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL RLS test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#       The SQL test switches the session user to thsync and to authenticator
#       (the PostgREST login role), so the URL's user must be a superuser.
#   bash <this script> --print-sql                          print the SQL test
#
# The SQL test uses synthetic identities only, runs in one transaction and
# always rolls back.
set -euo pipefail

migration="supabase/migrations/202610180001_sync_tables.sql"
migrations_dir="supabase/migrations"

print_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'FAIL setup: the sync SQL test needs a superuser connection (it switches the session user to thsync and authenticator)';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticator') then
    raise exception 'FAIL setup: role authenticator (the PostgREST login role) is missing';
  end if;
end;
$setup$;

select set_config('th944.superuser', session_user, true);

create schema th944_test;

create function th944_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

create function th944_test.refused(
  p_sql text, p_states text[], p_message_like text, p_label text
)
returns void language plpgsql set search_path = '' as $f$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate = any (p_states) and sqlerrm like p_message_like then
      raise notice 'PASS % (% %)', p_label, sqlstate, sqlerrm;
      return;
    end if;
    raise exception 'FAIL % (got % %)', p_label, sqlstate, sqlerrm;
  end;
  raise exception 'FAIL % (statement succeeded)', p_label;
end;
$f$;

create function th944_test.affects(p_sql text, p_rows integer, p_label text)
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

-- Switches the session to p_login acting as authenticated for p_sub, the way
-- the sync service (thsync) and PostgREST (authenticator) do; or back to the
-- superuser that started the test. No SET clause on purpose: SET LOCAL inside
-- a function with one would be undone when it returns.
create function th944_test.become(p_login text, p_sub text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('sub', p_sub, 'role', 'authenticated')::text, true);
  if p_login <> pg_catalog.current_setting('th944.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

-- Privileges held by anon, authenticated, thsync and PUBLIC, as one sorted string.
create function th944_test.table_acl(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s:%s:%s', c.relname, coalesce(r.rolname, 'PUBLIC'),
           a.privilege_type), ',' order by c.relname, coalesce(r.rolname, 'PUBLIC'),
           a.privilege_type), '')
  from pg_catalog.pg_class as c
  cross join lateral pg_catalog.aclexplode(c.relacl) as a
  left join pg_catalog.pg_roles as r on r.oid = a.grantee
  where c.oid = any (p_tables)
    and (a.grantee = 0 or r.rolname in ('anon', 'authenticated', 'thsync'));
$f$;

create function th944_test.column_acl(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s.%s:%s:%s', c.relname, at.attname,
           coalesce(r.rolname, 'PUBLIC'), a.privilege_type), ','
           order by c.relname, at.attname, coalesce(r.rolname, 'PUBLIC'), a.privilege_type), '')
  from pg_catalog.pg_attribute as at
  join pg_catalog.pg_class as c on c.oid = at.attrelid
  cross join lateral pg_catalog.aclexplode(at.attacl) as a
  left join pg_catalog.pg_roles as r on r.oid = a.grantee
  where c.oid = any (p_tables) and not at.attisdropped
    and (a.grantee = 0 or r.rolname in ('anon', 'authenticated', 'thsync'));
$f$;

create function th944_test.function_acl(p_functions regprocedure[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s:%s:%s', p.proname, coalesce(r.rolname, 'PUBLIC'),
           a.privilege_type), ',' order by p.proname, coalesce(r.rolname, 'PUBLIC')), '')
  from pg_catalog.pg_proc as p
  cross join lateral pg_catalog.aclexplode(
    coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
  left join pg_catalog.pg_roles as r on r.oid = a.grantee
  where p.oid = any (p_functions)
    and (a.grantee = 0 or r.rolname in ('anon', 'authenticated', 'thsync'));
$f$;

create function th944_test.policy_list(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s:%s:%s:%s', c.relname, p.polname, p.polcmd,
           p.polpermissive), ',' order by c.relname, p.polname), '')
  from pg_catalog.pg_policy as p
  join pg_catalog.pg_class as c on c.oid = p.polrelid
  where c.oid = any (p_tables);
$f$;

create function th944_test.fk_list(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s(%s)->%s(%s):%s', c.conrelid::regclass,
           (select string_agg(a.attname, '+' order by k.n) from unnest(c.conkey) with ordinality as k(attnum, n)
              join pg_catalog.pg_attribute as a on a.attrelid = c.conrelid and a.attnum = k.attnum),
           c.confrelid::regclass,
           (select string_agg(a.attname, '+' order by k.n) from unnest(c.confkey) with ordinality as k(attnum, n)
              join pg_catalog.pg_attribute as a on a.attrelid = c.confrelid and a.attnum = k.attnum),
           c.confdeltype), ',' order by c.conrelid::regclass::text, c.conname), '')
  from pg_catalog.pg_constraint as c
  where c.contype = 'f' and c.conrelid = any (p_tables);
$f$;

grant usage on schema th944_test to public;
grant execute on all functions in schema th944_test to public;

-- Synthetic identities only.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-000000944001', 'synthetic-user-01@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000944002', 'synthetic-user-02@example.test',
   'authenticated', 'authenticated');
select th944_test.ok(
  (select count(*) from public.profiles
   where id in ('00000000-0000-4000-8000-000000944001',
                '00000000-0000-4000-8000-000000944002')) = 2,
  'setup: the signup trigger created both synthetic profiles');

-- Synthetic consent documents: consent rows take their text from these.
insert into public.consent_documents (purpose, version, locale, body, effective_from) values
  ('core', 'v1', 'en', 'Synthetic core wording', now()),
  ('core', 'v2', 'en', 'Synthetic core wording v2', now());

-- The thsync role -------------------------------------------------------------
select th944_test.ok(
  (select not rolcanlogin and not rolinherit and not rolsuper and not rolbypassrls
     and not rolcreaterole and not rolcreatedb and not rolreplication
   from pg_catalog.pg_roles where rolname = 'thsync'),
  'thsync: nologin, noinherit, no superuser, no bypassrls, cannot create roles or databases or replicate');
select th944_test.ok(
  (select string_agg(m.roleid::regrole::text || ':inherit=' || m.inherit_option::text, ',')
   from pg_catalog.pg_auth_members as m
   where m.member = 'thsync'::regrole) = 'authenticated:inherit=false',
  'thsync: member of authenticated only, without inheriting its privileges');
select th944_test.ok(
  not exists (select 1 from pg_catalog.pg_auth_members as m
              where m.roleid = 'thsync'::regrole and (m.inherit_option or m.set_option)),
  'thsync: no role inherits from or can SET ROLE to thsync');
select th944_test.ok(
  (select count(*) from pg_catalog.pg_class where relowner = 'thsync'::regrole) = 0
  and (select count(*) from pg_catalog.pg_proc where proowner = 'thsync'::regrole) = 0
  and (select count(*) from pg_catalog.pg_namespace where nspowner = 'thsync'::regrole) = 0
  and (select count(*) from pg_catalog.pg_type where typowner = 'thsync'::regrole) = 0,
  'thsync: owns no tables, functions, schemas or types');
select th944_test.ok(
  not exists (
    select 1 from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(c.relacl) as a
    where a.grantee = 'thsync'::regrole)
  and not exists (
    select 1 from pg_catalog.pg_attribute as at
    cross join lateral pg_catalog.aclexplode(at.attacl) as a
    where a.grantee = 'thsync'::regrole)
  and not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(p.proacl) as a
    where a.grantee = 'thsync'::regrole)
  and not exists (
    select 1 from pg_catalog.pg_namespace as n
    cross join lateral pg_catalog.aclexplode(n.nspacl) as a
    where a.grantee = 'thsync'::regrole),
  'thsync: no direct privilege on any table, column, function or schema');

-- Privileges and policies -----------------------------------------------------
-- Pinned so that an accidental grant or policy change fails this test.
select th944_test.ok(
  th944_test.table_acl(array['public.profiles', 'public.quit_plans',
    'public.program_data', 'public.programmes', 'public.enrolments',
    'public.programme_consents', 'public.account_consents']::regclass[]) =
  'account_consents:authenticated:SELECT,'
  'enrolments:authenticated:DELETE,enrolments:authenticated:SELECT,'
  'profiles:authenticated:SELECT,'
  'program_data:authenticated:DELETE,program_data:authenticated:INSERT,'
  'program_data:authenticated:SELECT,program_data:authenticated:UPDATE,'
  'programme_consents:authenticated:SELECT,'
  'programmes:authenticated:SELECT,'
  'quit_plans:authenticated:SELECT',
  'existing tables: anon/authenticated/thsync/PUBLIC table privileges unchanged');
select th944_test.ok(
  th944_test.column_acl(array['public.profiles', 'public.quit_plans',
    'public.program_data', 'public.programmes', 'public.enrolments',
    'public.programme_consents', 'public.account_consents']::regclass[]) =
  'account_consents.consent_version:authenticated:INSERT,'
  'account_consents.locale:authenticated:INSERT,'
  'account_consents.purpose:authenticated:INSERT,'
  'account_consents.revoked_at:authenticated:UPDATE,'
  'account_consents.user_id:authenticated:INSERT,'
  'enrolments.mode:authenticated:INSERT,enrolments.mode:authenticated:UPDATE,'
  'enrolments.programme_code:authenticated:INSERT,'
  'enrolments.status:authenticated:INSERT,enrolments.status:authenticated:UPDATE,'
  'enrolments.user_id:authenticated:INSERT,'
  'profiles.avatar_path:authenticated:UPDATE,profiles.display_name:authenticated:UPDATE,'
  'profiles.locale:authenticated:UPDATE,profiles.onboarding_completed:authenticated:UPDATE,'
  'profiles.time_zone:authenticated:UPDATE,'
  'programme_consents.consent_version:authenticated:INSERT,'
  'programme_consents.enrolment_id:authenticated:INSERT,'
  'programme_consents.locale:authenticated:INSERT,'
  'programme_consents.purpose:authenticated:INSERT,'
  'programme_consents.recipient_ref:authenticated:INSERT,'
  'programme_consents.revoked_at:authenticated:UPDATE,'
  'programme_consents.superseded_by:authenticated:UPDATE,'
  'quit_plans.care_team_reminder:authenticated:INSERT,quit_plans.care_team_reminder:authenticated:UPDATE,'
  'quit_plans.custom_quit_reason:authenticated:INSERT,quit_plans.custom_quit_reason:authenticated:UPDATE,'
  'quit_plans.custom_smoking_trigger:authenticated:INSERT,quit_plans.custom_smoking_trigger:authenticated:UPDATE,'
  'quit_plans.daily_cigarette_use:authenticated:INSERT,quit_plans.daily_cigarette_use:authenticated:UPDATE,'
  'quit_plans.preparation_tasks:authenticated:INSERT,quit_plans.preparation_tasks:authenticated:UPDATE,'
  'quit_plans.quit_date:authenticated:INSERT,quit_plans.quit_date:authenticated:UPDATE,'
  'quit_plans.quit_day_check_in:authenticated:INSERT,quit_plans.quit_day_check_in:authenticated:UPDATE,'
  'quit_plans.quit_plan_path:authenticated:INSERT,quit_plans.quit_plan_path:authenticated:UPDATE,'
  'quit_plans.quit_reasons:authenticated:INSERT,quit_plans.quit_reasons:authenticated:UPDATE,'
  'quit_plans.readiness_path:authenticated:INSERT,quit_plans.readiness_path:authenticated:UPDATE,'
  'quit_plans.smoking_triggers:authenticated:INSERT,quit_plans.smoking_triggers:authenticated:UPDATE,'
  'quit_plans.support_people:authenticated:INSERT,quit_plans.support_people:authenticated:UPDATE,'
  'quit_plans.top_quit_reason:authenticated:INSERT,quit_plans.top_quit_reason:authenticated:UPDATE,'
  'quit_plans.treatment_support:authenticated:INSERT,quit_plans.treatment_support:authenticated:UPDATE,'
  'quit_plans.user_id:authenticated:INSERT,quit_plans.user_id:authenticated:UPDATE',
  'existing tables: anon/authenticated/thsync/PUBLIC column privileges unchanged');
select th944_test.ok(
  th944_test.policy_list(array['public.profiles', 'public.quit_plans',
    'public.program_data', 'public.programmes', 'public.enrolments',
    'public.programme_consents', 'public.account_consents']::regclass[]) =
  'account_consents:account_consents_insert_own:a:t,account_consents:account_consents_select_own:r:t,'
  'account_consents:account_consents_update_own:w:t,'
  'enrolments:enrolments_delete_own:d:t,enrolments:enrolments_insert_own:a:t,'
  'enrolments:enrolments_select_own:r:t,enrolments:enrolments_update_own:w:t,'
  'profiles:profiles_select_own:r:t,profiles:profiles_update_own:w:t,'
  'program_data:program_data_delete_own:d:t,program_data:program_data_insert_own:a:t,'
  'program_data:program_data_select_own:r:t,program_data:program_data_update_own:w:t,'
  'programme_consents:programme_consents_insert_own:a:t,'
  'programme_consents:programme_consents_select_own:r:t,'
  'programme_consents:programme_consents_update_own:w:t,'
  'programmes:programmes_select_authenticated:r:t,'
  'quit_plans:quit_plans_insert_own:a:t,quit_plans:quit_plans_select_own:r:t,'
  'quit_plans:quit_plans_update_own:w:t',
  'existing tables: policies unchanged');
select th944_test.ok(
  th944_test.function_acl(array['public.has_consent(uuid,text,text)',
    'public.deletion_barrier_open()', 'public.delete_my_app_data(text)',
    'public.begin_account_deletion(text)', 'public.sync_writer_session()',
    'public.sync_area_match_enrolment()', 'public.sync_lapse_append_only()']::regprocedure[]) =
  'begin_account_deletion:authenticated:EXECUTE,'
  'deletion_barrier_open:authenticated:EXECUTE,has_consent:authenticated:EXECUTE,'
  'sync_writer_session:authenticated:EXECUTE',
  'functions: execute only for authenticated where intended; never anon, thsync or PUBLIC');
select th944_test.ok(
  (select prosecdef and proconfig = array['search_path=""']
   from pg_catalog.pg_proc where oid = 'public.delete_my_app_data(text)'::regprocedure),
  'delete_my_app_data stays security definer with an empty search_path');
select th944_test.ok(
  th944_test.table_acl(array['public.sync_account', 'public.sync_area',
    'public.sync_answer', 'public.sync_lapse']::regclass[]) =
  'sync_account:authenticated:SELECT,sync_answer:authenticated:SELECT,'
  'sync_area:authenticated:SELECT,sync_lapse:authenticated:SELECT',
  'sync tables: select only at table level, nothing for anon, thsync or PUBLIC');
select th944_test.ok(
  th944_test.column_acl(array['public.sync_account', 'public.sync_area',
    'public.sync_answer', 'public.sync_lapse']::regclass[]) =
  'sync_account.change_seq:authenticated:UPDATE,sync_account.user_id:authenticated:INSERT,'
  'sync_answer.payload:authenticated:INSERT,sync_answer.payload:authenticated:UPDATE,'
  'sync_answer.programme_code:authenticated:INSERT,sync_answer.screen_id:authenticated:INSERT,'
  'sync_answer.user_id:authenticated:INSERT,'
  'sync_area.change_seq:authenticated:INSERT,sync_area.change_seq:authenticated:UPDATE,'
  'sync_area.enrolment_id:authenticated:INSERT,sync_area.programme_code:authenticated:INSERT,'
  'sync_area.revision:authenticated:INSERT,sync_area.revision:authenticated:UPDATE,'
  'sync_area.user_id:authenticated:INSERT,'
  'sync_lapse.at:authenticated:INSERT,sync_lapse.context:authenticated:INSERT,'
  'sync_lapse.ordinal:authenticated:INSERT,sync_lapse.programme_code:authenticated:INSERT,'
  'sync_lapse.severity:authenticated:INSERT,sync_lapse.user_id:authenticated:INSERT',
  'sync tables: only the intended column privileges; no update on lapses, no delete anywhere');
select th944_test.ok(
  th944_test.policy_list(array['public.sync_account', 'public.sync_area',
    'public.sync_answer', 'public.sync_lapse']::regclass[]) =
  'sync_account:sync_account_insert_sync:a:t,sync_account:sync_account_select_own:r:t,'
  'sync_account:sync_account_update_sync:w:t,'
  'sync_answer:sync_answer_insert_sync:a:t,sync_answer:sync_answer_select_own:r:t,'
  'sync_answer:sync_answer_update_sync:w:t,'
  'sync_area:sync_area_insert_sync:a:t,sync_area:sync_area_select_own:r:t,'
  'sync_area:sync_area_update_sync:w:t,'
  'sync_lapse:sync_lapse_insert_sync:a:t,sync_lapse:sync_lapse_select_own:r:t',
  'sync tables: exactly the intended policies (no delete policy; no update policy on lapses)');
select th944_test.ok(
  (select bool_and(relrowsecurity and relforcerowsecurity) from pg_catalog.pg_class
   where oid in ('public.sync_account'::regclass, 'public.sync_area'::regclass,
                 'public.sync_answer'::regclass, 'public.sync_lapse'::regclass,
                 'public.programmes'::regclass, 'public.enrolments'::regclass,
                 'public.programme_consents'::regclass, 'public.account_consents'::regclass,
                 'public.profiles'::regclass, 'public.quit_plans'::regclass,
                 'public.program_data'::regclass)),
  'RLS enabled and forced on the sync tables and the existing tables');
select th944_test.ok(
  th944_test.fk_list(array['public.sync_account', 'public.sync_area',
    'public.sync_answer', 'public.sync_lapse']::regclass[]) =
  'public.sync_account(user_id)->auth.users(id):c,'
  'public.sync_answer(user_id+programme_code)->public.sync_area(user_id+programme_code):c,'
  'public.sync_area(enrolment_id)->public.enrolments(id):c,'
  'public.sync_area(programme_code)->public.programmes(code):a,'
  'public.sync_area(user_id)->public.sync_account(user_id):c,'
  'public.sync_lapse(user_id+programme_code)->public.sync_area(user_id+programme_code):c',
  'sync tables: owner FK to auth.users, enrolment FK, programme FK, cascades as designed');

set local role anon;
select th944_test.refused('select count(*) from public.sync_answer',
  array['42501'], 'permission denied%', 'anon cannot read sync answers');
select th944_test.refused('select count(*) from public.sync_lapse',
  array['42501'], 'permission denied%', 'anon cannot read sync lapses');
reset role;

-- User A: enrolments and consents through the API (PostgREST stand-in) -------
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
with i as (
  insert into public.enrolments (user_id, programme_code, mode)
  values ('00000000-0000-4000-8000-000000944001', 'bf', 'quit') returning id
) select set_config('th944.a_bf', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000944001', 'hw') returning id
) select set_config('th944.a_hw', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, status, mode)
  values ('00000000-0000-4000-8000-000000944001', 'sf', 'learn_only', 'reduce') returning id
) select set_config('th944.a_sf', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values
  (current_setting('th944.a_bf')::uuid, 'core', 'v1', 'en'),
  (current_setting('th944.a_hw')::uuid, 'core', 'v1', 'en');

-- The API cannot write sync data, even for its own caller.
select th944_test.refused(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000944001'')',
  array['42501'], '%row-level security%', 'API session: cannot create the sync account');

-- User A through the sync service --------------------------------------------
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.ok(session_user = 'thsync' and current_user = 'authenticated'
  and auth.uid() = '00000000-0000-4000-8000-000000944001',
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th944_test.affects(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000944001'')',
  1, 'A sync: creates the sync account');
select th944_test.refused(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000944002'')',
  array['42501'], '%row-level security%', 'A sync: cannot create B''s sync account');
select th944_test.affects(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', %L, ''bf'', 1, 1)',
  current_setting('th944.a_bf')), 1, 'A sync: BreatheFree area with live core consent');
select th944_test.affects(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', %L, ''hw'', 1, 2)',
  current_setting('th944.a_hw')), 1, 'A sync: Heartwise area with live core consent');
select th944_test.refused(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', %L, ''sf'', 1, 3)',
  current_setting('th944.a_sf')),
  array['42501'], '%row-level security%', 'A sync: ScrollFree area refused without core consent');
select th944_test.refused(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', %L, ''st'', 1, 3)',
  current_setting('th944.a_bf')),
  array['TH007'], '%must match its enrolment%',
  'A sync: cannot file a programme with no enrolment under another programme''s enrolment');
select th944_test.refused(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', gen_random_uuid(), ''st'', 1, 3)',
  array['TH007'], '%must match its enrolment%', 'A sync: area without an enrolment refused');

select th944_test.affects(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q1'', ''{"chips":{"0":[1,2]}}''),
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_meds'', ''{"text":{"0":"synthetic"}}''),
   (''00000000-0000-4000-8000-000000944001'', ''hw'', ''hw_targets'', ''{"slider":{"0":120}}'')',
  3, 'A sync: answers stored for consented programmes');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''sf'', ''sf_plan'', ''{}'')',
  array['42501'], '%row-level security%', 'A sync: ScrollFree answer refused (no consent, no area)');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''st'', ''st_range'', ''{}'')',
  array['42501'], '%row-level security%', 'A sync: answer for a programme with no enrolment refused');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q2'', ''[1]'')',
  array['23514'], '%', 'A sync: answer payload must be a JSON object');
select th944_test.refused(format(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q2'', %L)',
  jsonb_build_object('text', jsonb_build_object('0', repeat('x', 33000)))),
  array['23514'], '%', 'A sync: answer payload over 32 KiB refused');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''hw/hw_targets'', ''{}'')',
  array['23514'], '%', 'A sync: screen id may not name another programme');
select th944_test.affects(
  'update public.sync_answer set payload = ''{"chips":{"0":[3]}}''
   where programme_code = ''bf'' and screen_id = ''bf_q1''',
  1, 'A sync: updates an answer');
select th944_test.refused(
  'update public.sync_answer set programme_code = ''hw'' where screen_id = ''bf_q1''',
  array['42501'], 'permission denied%', 'A sync: cannot move an answer to another programme');
select th944_test.refused(
  'update public.sync_answer set user_id = ''00000000-0000-4000-8000-000000944002''',
  array['42501'], 'permission denied%', 'A sync: cannot reassign an answer');
select th944_test.refused('delete from public.sync_answer',
  array['42501'], 'permission denied%', 'A sync: cannot delete answers (deletion goes through the API)');
select th944_test.affects(
  'update public.sync_area set revision = 2, change_seq = 3 where programme_code = ''bf''',
  1, 'A sync: bumps a revision');
select th944_test.refused(format(
  'update public.sync_area set enrolment_id = %L where programme_code = ''bf''',
  current_setting('th944.a_hw')),
  array['42501'], 'permission denied%', 'A sync: cannot re-point an area at another enrolment');
select th944_test.affects('update public.sync_account set change_seq = 3',
  1, 'A sync: bumps the change counter');
select th944_test.refused('delete from public.sync_area',
  array['42501'], 'permission denied%', 'A sync: cannot delete areas');
select th944_test.refused('delete from public.sync_account',
  array['42501'], 'permission denied%', 'A sync: cannot delete the sync account');

-- Lapses are append-only.
select th944_test.affects(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at, severity, context) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 0, now(), ''slip'', ''["synthetic"]''),
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 1, now(), ''slip'', ''[]'')',
  2, 'A sync: appends lapses');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 0, now())',
  array['23505'], '%', 'A sync: an existing lapse cannot be replaced');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at, context) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 9, now(), ''{}'')',
  array['23514'], '%', 'A sync: lapse context must be a JSON array');
select th944_test.refused('update public.sync_lapse set severity = ''changed''',
  array['42501'], 'permission denied%', 'A sync: cannot update a lapse');
select th944_test.refused('delete from public.sync_lapse',
  array['42501'], 'permission denied%', 'A sync: cannot delete a lapse');
select th944_test.refused('select public.delete_my_app_data(''DELETE'')',
  array['42501'], 'permission denied for function delete_my_app_data', 'A sync: the sync service cannot delete the account');

-- Revoking one programme's core consent stops its writes, and only its writes.
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
select th944_test.affects(format(
  'update public.programme_consents set revoked_at = now()
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th944.a_bf')), 1, 'A API: revokes BreatheFree core consent');
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q3'', ''{}'')',
  array['42501'], '%row-level security%', 'A sync: no new BreatheFree answer after core revocation');
select th944_test.refused(
  'update public.sync_answer set payload = ''{}'' where programme_code = ''bf''',
  array['42501'], '%row-level security%', 'A sync: no BreatheFree answer update after core revocation');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 2, now())',
  array['42501'], '%row-level security%', 'A sync: no BreatheFree lapse after core revocation');
select th944_test.refused(
  'update public.sync_area set revision = 3 where programme_code = ''bf''',
  array['42501'], '%row-level security%', 'A sync: no BreatheFree revision bump after core revocation');
select th944_test.affects(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''hw'', ''hw_plan'', ''{"option":{"0":1}}'')',
  1, 'A sync: Heartwise still writable (consent is per programme)');
select th944_test.affects(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''hw'', 0, now())',
  1, 'A sync: Heartwise lapse appended');
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th944.a_bf')::uuid, 'core', 'v2', 'en');
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.affects(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 2, now())',
  1, 'A sync: BreatheFree writable again after a new core grant');

-- Even a privileged role cannot rewrite a lapse.
select th944_test.become(current_setting('th944.superuser'), '');
select th944_test.refused('update public.sync_lapse set severity = ''changed''',
  array['TH008'], '%append-only%', 'superuser: the trigger refuses any lapse update');

-- User B ---------------------------------------------------------------------
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944002');
select th944_test.ok(
  (select count(*) from public.sync_account) = 0
  and (select count(*) from public.sync_area) = 0
  and (select count(*) from public.sync_answer) = 0
  and (select count(*) from public.sync_lapse) = 0,
  'B sync: cannot read any of A''s sync rows');
select th944_test.affects('update public.sync_answer set payload = ''{}''',
  0, 'B sync: cannot update A''s answers');
select th944_test.affects('update public.sync_account set change_seq = 99',
  0, 'B sync: cannot update A''s sync account');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q3'', ''{}'')',
  array['42501'], '%row-level security%', 'B sync: cannot write an answer for A');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 3, now())',
  array['42501'], '%row-level security%', 'B sync: cannot append a lapse for A');
select th944_test.affects(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000944002'')',
  1, 'B sync: creates its own sync account');
select th944_test.refused(format(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944002'', %L, ''bf'', 1, 1)',
  current_setting('th944.a_bf')),
  array['TH007', '42501'], '%', 'B sync: cannot attach an area to A''s enrolment');
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944002');
select th944_test.ok(
  (select count(*) from public.sync_answer) = 0 and (select count(*) from public.sync_lapse) = 0,
  'B API: cannot read A''s sync rows');

-- The API reads A's sync rows through RLS, and still cannot write them.
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
select th944_test.ok(
  (select count(*) from public.sync_account) = 1
  and (select count(*) from public.sync_area) = 2
  and (select count(*) from public.sync_answer) = 4
  and (select count(*) from public.sync_lapse) = 4,
  'A API: reads A''s sync rows (1 account, 2 areas, 4 answers, 4 lapses)');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q3'', ''{}'')',
  array['42501'], '%row-level security%', 'A API: cannot write a sync answer');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 3, now())',
  array['42501'], '%row-level security%', 'A API: cannot append a lapse');
select th944_test.refused(
  'insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
   values (''00000000-0000-4000-8000-000000944001'', gen_random_uuid(), ''ca'', 1, 1)',
  array['42501', 'TH007'], '%', 'A API: cannot create a sync area');
select th944_test.affects('update public.sync_answer set payload = ''{}''',
  0, 'A API: cannot update sync answers');
select th944_test.affects('update public.sync_account set change_seq = 99',
  0, 'A API: cannot update the sync account');

-- Leaving keeps the data read-only; "delete now" removes it -------------------
select th944_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L',
  current_setting('th944.a_hw')), 1, 'A API: leaves Heartwise');
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''hw'', ''hw_q1'', ''{}'')',
  array['42501'], '%row-level security%', 'A sync: no Heartwise answer after leaving');
select th944_test.refused(
  'update public.sync_answer set payload = ''{}'' where programme_code = ''hw''',
  array['42501'], '%row-level security%', 'A sync: no Heartwise update after leaving');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''hw'', 1, now())',
  array['42501'], '%row-level security%', 'A sync: no Heartwise lapse after leaving');
select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
select th944_test.ok(
  (select count(*) from public.sync_answer where programme_code = 'hw') = 2
  and (select count(*) from public.sync_lapse where programme_code = 'hw') = 1,
  'A API: Heartwise sync data is kept after leaving');
select th944_test.affects(format(
  'delete from public.enrolments where id = %L',
  current_setting('th944.a_hw')), 1, 'A API: deletes Heartwise now');
select th944_test.become(current_setting('th944.superuser'), '');
select th944_test.ok(
  (select count(*) from public.sync_area
   where user_id = '00000000-0000-4000-8000-000000944001' and programme_code = 'hw') = 0
  and (select count(*) from public.sync_answer
       where user_id = '00000000-0000-4000-8000-000000944001' and programme_code = 'hw') = 0
  and (select count(*) from public.sync_lapse
       where user_id = '00000000-0000-4000-8000-000000944001' and programme_code = 'hw') = 0,
  'delete-now removed the Heartwise area, answers and lapses (cascade)');
select th944_test.ok(
  (select count(*) from public.sync_answer
   where user_id = '00000000-0000-4000-8000-000000944001' and programme_code = 'bf') = 2
  and (select count(*) from public.sync_lapse
       where user_id = '00000000-0000-4000-8000-000000944001' and programme_code = 'bf') = 3,
  'delete-now left the BreatheFree sync data untouched');

-- Account deletion -----------------------------------------------------------
select set_config('th944.a_counts', jsonb_build_object(
  'profiles', 1, 'quit_plans', 0, 'program_data', 0,
  'enrolments', (select count(*) from public.enrolments
                 where user_id = '00000000-0000-4000-8000-000000944001'),
  'programme_consents', (select count(*) from public.programme_consents c
                         join public.enrolments e on e.id = c.enrolment_id
                         where e.user_id = '00000000-0000-4000-8000-000000944001'),
  'account_consents', 0,
  'sync_answers', (select count(*) from public.sync_answer
                   where user_id = '00000000-0000-4000-8000-000000944001'),
  'sync_lapses', (select count(*) from public.sync_lapse
                  where user_id = '00000000-0000-4000-8000-000000944001'),
  'sync_areas', (select count(*) from public.sync_area
                 where user_id = '00000000-0000-4000-8000-000000944001'),
  'sync_accounts', (select count(*) from public.sync_account
                    where user_id = '00000000-0000-4000-8000-000000944001')
)::text, true);
select th944_test.ok(
  current_setting('th944.a_counts')::jsonb @> '{"enrolments": 2, "programme_consents": 2,
    "sync_answers": 2, "sync_lapses": 3, "sync_areas": 1, "sync_accounts": 1}'::jsonb,
  'A has 2 enrolments, 2 programme consents, 2 sync answers, 3 lapses, 1 area and 1 sync account before deletion');

select th944_test.become('authenticator', '00000000-0000-4000-8000-000000944001');
-- A recent sign-in, which begin_account_deletion requires.
select set_config('request.jwt.claims', (current_setting('request.jwt.claims')::jsonb
  || jsonb_build_object('amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30))))::text, true);
select th944_test.ok(public.begin_account_deletion('DELETE'), 'A API: deletion barrier set');
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.refused(
  'insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', ''bf_q3'', ''{}'')',
  array['42501'], '%row-level security%', 'A sync: no new answer once deletion has started');
select th944_test.refused(
  'update public.sync_answer set payload = ''{}'' where programme_code = ''bf''',
  array['42501'], '%row-level security%', 'A sync: no answer update once deletion has started');
select th944_test.refused(
  'insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
   (''00000000-0000-4000-8000-000000944001'', ''bf'', 3, now())',
  array['42501'], '%row-level security%', 'A sync: no new lapse once deletion has started');
select th944_test.refused('update public.sync_account set change_seq = 10',
  array['42501'], '%row-level security%', 'A sync: no cursor bump once deletion has started');

-- Owner context, as delete_my_account runs it: the superuser with A's claims.
select th944_test.become(current_setting('th944.superuser'), '00000000-0000-4000-8000-000000944001');
select set_config('th944.a_receipt', public.delete_my_app_data('DELETE')::text, true);
select th944_test.ok(
  current_setting('th944.a_receipt')::jsonb = current_setting('th944.a_counts')::jsonb,
  'A owner: delete_my_app_data returns counts only, one per deleted table, including all four sync tables');
select th944_test.become('thsync', '00000000-0000-4000-8000-000000944001');
select th944_test.refused(
  'insert into public.sync_account (user_id) values (''00000000-0000-4000-8000-000000944001'')',
  array['42501'], '%row-level security%', 'A sync: no sync account after the profile is deleted');

select th944_test.become(current_setting('th944.superuser'), '');
select th944_test.ok(
  (select count(*) from public.sync_account
   where user_id = '00000000-0000-4000-8000-000000944001') = 0
  and (select count(*) from public.sync_area
       where user_id = '00000000-0000-4000-8000-000000944001') = 0
  and (select count(*) from public.sync_answer
       where user_id = '00000000-0000-4000-8000-000000944001') = 0
  and (select count(*) from public.sync_lapse
       where user_id = '00000000-0000-4000-8000-000000944001') = 0
  and (select count(*) from public.enrolments
       where user_id = '00000000-0000-4000-8000-000000944001') = 0
  and (select count(*) from public.profiles
       where id = '00000000-0000-4000-8000-000000944001') = 0,
  'deletion removed every A sync row, enrolment and the profile');
select th944_test.ok(
  (select count(*) from public.sync_account
   where user_id = '00000000-0000-4000-8000-000000944002') = 1,
  'deletion left B''s sync account untouched');

select 'TH944_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Sync migration check failed: $1" >&2
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

require() {
  grep -Eiq "$1" "$migration" || fail "$2"
}

count() {
  grep -Eic "$1" "$migration" || true
}

first_line() {
  grep -Ein "$1" "$migration" | head -n 1 | cut -d: -f1
}

# Legacy cleanup comes first, and only drops the old account_id-keyed tables.
drop_line=$(first_line '^drop table if exists public\.sync_lapse, public\.sync_answer, public\.sync_area, public\.sync_account;$')
create_line=$(first_line '^create table ')
[[ -n "$drop_line" ]] || fail 'legacy sync_* drop missing'
[[ -n "$create_line" && "$drop_line" -lt "$create_line" ]] || fail 'legacy drop must come before any create table'
require "a\\.attname = 'account_id'" 'legacy drop guarded on the legacy account_id column'
require 'refusing to drop' 'legacy guard stops on unexpected sync_* tables'
require "format\\('select exists \\(select 1 from public\\.%I\\)'" 'legacy guard checks each legacy table for rows'
require 'has rows; export them' 'legacy guard stops on a non-empty legacy table'
if grep -Ei '^drop ' "$migration" | grep -Eiq 'cascade'; then
  fail 'no drop may cascade (a dependent object must stop the migration)'
fi

# The role: non-privileged, NOLOGIN, NOINHERIT, member of authenticated only.
require '^    create role thsync nologin noinherit;$' 'thsync created nologin noinherit'
require 'rolsuper or rolbypassrls or rolcreaterole or rolcreatedb' 'thsync attributes asserted'
require '^grant authenticated to thsync;$' 'thsync is a member of authenticated'
require "array_agg\\(distinct m\\.roleid::regrole::text\\), '\\{\\}'\\) <> array\\['authenticated'\\]" 'thsync membership asserted to be exactly authenticated'
require 'bool_or\(m\.admin_option\)' 'thsync membership asserted without admin option'
require 'inherit_option\)' 'thsync membership asserted without inheritance'
require 'must be a member of authenticated only' 'thsync membership assertion raises'
if grep -Ei '(create|alter) role' "$migration" |
  grep -Eiq '(^|[[:space:]])(login|superuser|createrole|createdb|replication|bypassrls|inherit)([[:space:];]|$)|password'; then
  fail 'thsync must not get login, a credential or an elevated attribute in a migration'
fi
if grep -Eiq '(^|[^a-z])bypassrls' "$migration"; then
  fail 'no bypassrls anywhere'
fi
if grep -Ei 'to thsync' "$migration" | grep -Ev '^grant authenticated to thsync;$' | grep -q .; then
  fail 'thsync gets no direct grant other than membership in authenticated'
fi
if grep -Eiq 'owner to thsync' "$migration"; then
  fail 'thsync owns nothing'
fi
writer_body=$(sed -n '/create function public\.sync_writer_session()/,/^\$\$;/p' "$migration")
grep -Eq "^  select session_user = 'thsync';$" <<<"$writer_body" ||
  fail 'sync_writer_session must compare session_user with thsync'
grep -Eq '^security invoker$' <<<"$writer_body" || fail 'sync_writer_session must be security invoker'

# Tables: forced RLS, default grants revoked, select for authenticated.
tables=(sync_account sync_area sync_answer sync_lapse)
for t in "${tables[@]}"; do
  require "^create table public\\.$t \\($" "table public.$t"
  require "^alter table public\\.$t enable row level security;$" "RLS enabled on $t"
  require "^alter table public\\.$t force row level security;$" "RLS forced on $t"
  require "^revoke all on table public\\.$t from anon, authenticated;$" "default grants revoked on $t"
  require "^grant select on table public\\.$t to authenticated;$" "$t readable by authenticated"
  require "^on public\\.$t for select$" "select policy on $t"
done
[[ "$(count '^using \(\(select auth\.uid\(\)\) = user_id\);$')" -eq 4 ]] ||
  fail 'each table needs an owner-only select policy'
[[ "$(count '^alter table public\.sync_[a-z]+ force row level security;$')" -eq 4 ]] ||
  fail 'force row level security on exactly the 4 sync tables'

# Foreign keys: owner to auth.users, data hangs off the enrolment.
require '^  user_id uuid primary key references auth\.users\(id\) on delete cascade,$' 'sync_account owner FK to auth.users cascades'
require '^  user_id uuid not null references public\.sync_account\(user_id\) on delete cascade,$' 'sync_area owner FK cascades'
require '^  enrolment_id uuid not null references public\.enrolments\(id\) on delete cascade,$' 'sync_area hangs off the enrolment'
require '^  programme_code text not null references public\.programmes\(code\),$' 'sync_area programme FK'
require 'unique \(enrolment_id\)' 'one sync area per enrolment'
[[ "$(count 'references public\.sync_area\(user_id, programme_code\) on delete cascade')" -eq 2 ]] ||
  fail 'answers and lapses hang off sync_area with cascade'
require 'create trigger sync_area_match_enrolment' 'area must match its enrolment'
require "octet_length\\(payload::text\\) <= 32768" 'answer payload bounded to 32 KiB'
require "jsonb_typeof\\(payload\\) = 'object'" 'answer payload is an object'

# Not carried over from the earlier design: no enrolment or sharing copy, no account_id.
for col in enrolment_status enrolment_hidden joined_on share_ revoked; do
  if sed -n '/^create table /,/^);$/p' "$migration" | grep -Eiq "^  $col"; then
    fail "column $col must not exist (enrolment and consent live in enrolments and programme_consents)"
  fi
done
if sed -n '/^create table /,/^);$/p' "$migration" | grep -Eiq 'account_id|varchar'; then
  fail 'no account_id or varchar identity columns'
fi

# Lapses: append-only.
require '^before update on public\.sync_lapse$' 'lapse update trigger'
require "raise check_violation using message = 'Lapses are append-only';" 'lapse trigger refuses updates'
if grep -Eiq 'grant [^;]*update[^;]* on table public\.sync_lapse' "$migration" ||
  grep -Ei '^grant ' "$migration" | grep -Eiv ' on function ' |
  grep -Eiq '(^grant |[ ,(])(delete|truncate)([ ,(]|$)'; then
  fail 'no update grant on lapses and no delete or truncate grant on any sync table'
fi
if grep -Eiq '^on public\.sync_lapse for update$|^on public\.sync_[a-z]+ for (delete|all)$' "$migration"; then
  fail 'no update policy on lapses and no delete or all policy on sync tables'
fi

# Every write policy: owner, thsync session, deletion barrier, and (for
# programme data) the enrolment's core consent.
write_policies=0
while IFS= read -r block; do
  [[ -n "$block" ]] || continue
  write_policies=$((write_policies + 1))
  name=$(sed -E 's/^create policy "([a-z_]+)".*/\1/' <<<"$block")
  grep -q '(select auth.uid()) = user_id' <<<"$block" || fail "$name: owner check"
  [[ "$(grep -o 'public.sync_writer_session()' <<<"$block" | wc -l | tr -d ' ')" -ge 1 ]] ||
    fail "$name: thsync session check"
  grep -q 'with check' <<<"$block" || fail "$name: with check clause"
  grep -q 'public.deletion_barrier_open()' <<<"$block" || fail "$name: deletion barrier"
  if [[ "$name" != sync_account_* ]]; then
    grep -q "public.has_consent(" <<<"$block" || fail "$name: core consent"
  fi
  if grep -q ' for update ' <<<"$block"; then
    grep -Eq 'using \(\(select auth\.uid\(\)\) = user_id and public\.sync_writer_session\(\)\)' <<<"$block" ||
      fail "$name: update using clause must check owner and thsync session"
  fi
done < <(awk '
  /^create policy / { buf = $0; grab = 1; next }
  grab { buf = buf " " $0; if ($0 ~ /;$/) { if (buf ~ / for (insert|update) /) print buf; grab = 0 } }
' "$migration")
[[ "$write_policies" -eq 7 ]] || fail "expected 7 insert/update policies, found $write_policies"

# Functions: search_path pinned; the only security definer is delete_my_app_data.
functions=$(count '^create (or replace )?function ')
pinned=$(count "^set search_path = ''$")
[[ "$functions" -eq "$pinned" ]] || fail "$functions functions but $pinned with search_path = ''"
[[ "$(count '^security definer$')" -eq 1 ]] || fail 'only delete_my_app_data may be security definer'
require '^revoke all on function public\.sync_area_match_enrolment\(\)$' 'trigger function execute revoked'
require '^revoke all on function public\.sync_lapse_append_only\(\)$' 'trigger function execute revoked'
require '^grant execute on function public\.sync_writer_session\(\) to authenticated;$' 'writer check callable by policies'

# Deletion: delete_my_app_data re-created with everything earlier migrations
# added, plus the sync tables, deleted before enrolments.
delete_body=$(sed -n '/create or replace function public\.delete_my_app_data(p_confirmation text)/,/^\$\$;/p' "$migration")
[[ -n "$delete_body" ]] || fail 'delete_my_app_data must be re-created'
check_delete_body() {
  local body="$1" where="$2" t
  for t in sync_lapse sync_answer sync_area sync_account programme_consents enrolments \
    account_consents program_data quit_plans; do
    grep -Eq "delete from public\\.$t( |$)" <<<"$body" || fail "$where: deletion covers $t"
  done
  grep -q 'delete from public.profiles where id = caller_id' <<<"$body" || fail "$where: deletion covers profiles"
  for k in profiles quit_plans program_data enrolments programme_consents account_consents \
    sync_answers sync_lapses sync_areas sync_accounts; do
    grep -Eq "'$k', deleted_$k" <<<"$body" || fail "$where: receipt count $k"
  done
  grep -q "p_confirmation is distinct from 'DELETE'" <<<"$body" || fail "$where: explicit confirmation"
  grep -q 'Account deletion was not started' <<<"$body" || fail "$where: deletion barrier"
  grep -q "raise insufficient_privilege using message = 'Authentication required'" <<<"$body" ||
    fail "$where: authentication required"
  local sync_last enrol_first
  sync_last=$(grep -En 'delete from public\.sync_' <<<"$body" | tail -n 1 | cut -d: -f1)
  enrol_first=$(grep -En 'delete from public\.(programme_consents|enrolments)' <<<"$body" | head -n 1 | cut -d: -f1)
  [[ "$sync_last" -lt "$enrol_first" ]] || fail "$where: sync rows must be deleted before enrolments"
}
check_delete_body "$delete_body" "$migration"
grep -q 'if public.sync_writer_session() then' <<<"$delete_body" ||
  fail 'delete_my_app_data must refuse sync sessions (deletion goes through the API)'
require '^revoke all on function public\.delete_my_app_data\(text\)$' 'deletion default execute revoked'
require '^grant execute on function public\.delete_my_app_data\(text\) to authenticated;$' 'deletion granted to authenticated'

# Whatever migration defines delete_my_app_data last must still cover sync_*.
latest_delete=$(grep -El '^[[:space:]]*create (or replace )?function +("?public"?\.)?"?delete_my_app_data"? *\(' "$migrations_dir"/*.sql | LC_ALL=C sort | tail -n 1)
latest_body=$(sed -n '/function public\.delete_my_app_data(p_confirmation text)/,/^\$\$;/p' "$latest_delete")
check_delete_body "$latest_body" "$latest_delete (latest delete_my_app_data)"

# Never loosen.
if grep -Eiq 'disable row level security|no force row level security|security_barrier *= *false' "$migration"; then
  fail 'migration must not disable RLS'
fi
if grep -Eiq 'grant .* to (.*[^a-z_])?anon([^a-z_]|$)' "$migration"; then
  fail 'nothing is granted to anon'
fi
if grep -Eiq 'grant all' "$migration"; then
  fail 'no blanket grants'
fi
if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  fail 'migration must not contain credentials or service-role use'
fi

echo 'Sync migration static policy checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL RLS test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH944_SQL_TESTS_COMPLETE' || fail 'SQL RLS test did not complete'
  echo 'Sync SQL RLS test passed.'
fi
