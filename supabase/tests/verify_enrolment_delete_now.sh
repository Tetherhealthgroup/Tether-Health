#!/usr/bin/env bash
# Checks "Delete now" for one programme: members can no longer delete
# enrolments directly, public.delete_enrolment_now deletes one of the caller's
# enrolments and that programme's data (refusing in a fixed order), and no
# enrolment changes once account deletion has started.
#
#   bash supabase/tests/verify_enrolment_delete_now.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator, creates test roles and changes the owner of
#       delete_enrolment_now inside its transaction, so the URL's user must be
#       a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: as
#       authenticated with a recent sign-in, a synthetic member deletes its own
#       enrolment directly, and it reports:
#         TH914A_CONTROL_DIRECT_DELETE_REFUSED    (expected with the
#             migration: 42501 and the row is kept)
#         TH914A_CONTROL_DIRECT_DELETE_COMPLETED  (a tree without the
#             migration: the row is deleted)
#         TH914A_CONTROL_UNEXPECTED               (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180012_enrolment_delete_now.sql"
sign_in_source="supabase/migrations/202610180009_begin_deletion_recent_sign_in.sql"
owner_check_source="supabase/migrations/202610180008_delete_my_account.sql"
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
  if exists (
    select 1 from pg_catalog.unnest(array['anon', 'authenticated', 'authenticator', 'service_role', 'thsync']) as r(n)
    where not exists (select 1 from pg_catalog.pg_roles where rolname = r.n)) then
    raise exception 'FAIL setup: one of the roles anon, authenticated, authenticator, service_role, thsync is missing';
  end if;
  if pg_catalog.to_regclass('public.care_connections') is null
     or pg_catalog.to_regprocedure('auth.jwt()') is null
     or pg_catalog.to_regprocedure('public.delete_my_account(text)') is null then
    raise exception 'FAIL setup: the care tables, auth.jwt() and public.delete_my_account(text) are needed';
  end if;
end;
$setup$;

select set_config('th914a.superuser', session_user, true);

create schema th914a_test;

create function th914a_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with p_state and a message like p_message_like; when
-- p_hint is given, the error hint must equal it.
create function th914a_test.refused(
  p_sql text, p_state text, p_message_like text, p_label text, p_hint text default null
)
returns void language plpgsql set search_path = '' as $f$
declare
  got_hint text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics got_hint = pg_exception_hint;
    if sqlstate = p_state and sqlerrm like p_message_like
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

-- A value stored with set_config('th914a.<name>', ...).
create function th914a_test.v(p_name text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.current_setting('th914a.' || p_name)
$f$;

-- An amr claim with one password sign-in p_age seconds before now()
-- (negative: in the future).
create function th914a_test.amr_at(p_age numeric)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - p_age))
$f$;

-- Token claims for p_sub; a null p_sub or p_amr leaves that claim out.
create function th914a_test.claims(p_sub text, p_amr jsonb)
returns text language sql stable set search_path = '' as $f$
  select (pg_catalog.jsonb_build_object('role', 'authenticated', 'aud', 'authenticated')
          || case when p_sub is null then '{}'::jsonb
                  else pg_catalog.jsonb_build_object('sub', p_sub) end
          || case when p_amr is null then '{}'::jsonb
                  else pg_catalog.jsonb_build_object('amr', p_amr) end)::text
$f$;

-- Switches the session to p_login acting as p_role with p_claims, the way
-- PostgREST (authenticator) and the sync service (thsync) do; or back to the
-- superuser that started the test. No SET clause on purpose: SET LOCAL
-- inside a function with one would be undone when it returns.
create function th914a_test.act_as(p_login text, p_claims text, p_role text default 'authenticated')
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th914a.superuser') then
    execute pg_catalog.format('set local role %I', p_role);
  end if;
end;
$f$;

-- The rows delete_enrolment_now deletes for enrolment p_enrolment of p_user
-- in programme p_programme, keyed like its receipt.
create function th914a_test.rows_for(p_user uuid, p_enrolment uuid, p_programme text)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'quit_plans', case when p_programme = 'bf'
                       then (select count(*) from public.quit_plans where user_id = p_user) else 0 end,
    'program_data', (select count(*) from public.program_data
                     where user_id = p_user
                       and program_id = (select slug from public.programmes where code = p_programme)),
    'enrolments', (select count(*) from public.enrolments where id = p_enrolment),
    'programme_consents', (select count(*) from public.programme_consents where enrolment_id = p_enrolment),
    'sync_answers', (select count(*) from public.sync_answer
                     where user_id = p_user and programme_code = p_programme),
    'sync_lapses', (select count(*) from public.sync_lapse
                    where user_id = p_user and programme_code = p_programme),
    'sync_areas', (select count(*) from public.sync_area where enrolment_id = p_enrolment),
    'care_share_access', (select count(*) from public.care_share_access
                          where share_id in (select id from public.care_shares where enrolment_id = p_enrolment)),
    'care_messages', (select count(*) from public.care_messages
                      where enrolment_id = p_enrolment
                         or share_id in (select id from public.care_shares where enrolment_id = p_enrolment)),
    'care_shares', (select count(*) from public.care_shares where enrolment_id = p_enrolment),
    'caregiver_events', (select count(*) from public.caregiver_events
                         where caregiver_id in (select id from public.caregivers where enrolment_id = p_enrolment)),
    'caregivers', (select count(*) from public.caregivers where enrolment_id = p_enrolment),
    'observations', (select count(*) from public.observations where enrolment_id = p_enrolment),
    'programme_entries', (select count(*) from public.programme_entries where enrolment_id = p_enrolment),
    'rescue_events', (select count(*) from public.rescue_events where enrolment_id = p_enrolment),
    'lesson_progress', (select count(*) from public.lesson_progress where enrolment_id = p_enrolment),
    'programme_reminders', (select count(*) from public.programme_reminders where enrolment_id = p_enrolment),
    'record_routes', (select count(*) from public.record_routes where enrolment_id = p_enrolment))
$f$;

-- True when every count in p_counts is zero.
create function th914a_test.all_zero(p_counts jsonb)
returns boolean language sql immutable set search_path = '' as $f$
  select not exists (select 1 from pg_catalog.jsonb_each(p_counts) as e where e.value <> '0'::jsonb)
$f$;

-- The rows a user holds in every member table, keyed like the account
-- deletion receipt, plus the identity.
create function th914a_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'profiles', (select count(*) from public.profiles where id = p_user),
    'quit_plans', (select count(*) from public.quit_plans where user_id = p_user),
    'program_data', (select count(*) from public.program_data where user_id = p_user),
    'enrolments', (select count(*) from public.enrolments where user_id = p_user),
    'programme_consents', (select count(*) from public.programme_consents as c
                           join public.enrolments as e on e.id = c.enrolment_id
                           where e.user_id = p_user),
    'account_consents', (select count(*) from public.account_consents where user_id = p_user),
    'sync_answers', (select count(*) from public.sync_answer where user_id = p_user),
    'sync_lapses', (select count(*) from public.sync_lapse where user_id = p_user),
    'sync_areas', (select count(*) from public.sync_area where user_id = p_user),
    'sync_accounts', (select count(*) from public.sync_account where user_id = p_user),
    'care_share_access', (select count(*) from public.care_share_access where user_id = p_user),
    'care_messages', (select count(*) from public.care_messages where user_id = p_user),
    'care_shares', (select count(*) from public.care_shares where user_id = p_user),
    'caregiver_events', (select count(*) from public.caregiver_events where user_id = p_user),
    'caregivers', (select count(*) from public.caregivers where user_id = p_user),
    'care_connections', (select count(*) from public.care_connections where user_id = p_user),
    'supporters', (select count(*) from public.supporters where user_id = p_user),
    'users', (select count(*) from auth.users where id = p_user))
$f$;

-- p_before with each count named in p_receipt lowered by the receipt's count.
create function th914a_test.minus(p_before jsonb, p_receipt jsonb)
returns jsonb language sql immutable set search_path = '' as $f$
  select pg_catalog.jsonb_object_agg(b.key,
    case when p_receipt ? b.key
         then pg_catalog.to_jsonb((b.value #>> '{}')::bigint - (p_receipt ->> b.key)::bigint)
         else b.value end)
  from pg_catalog.jsonb_each(p_before) as b
$f$;

-- No row of any public table names an enrolment that no longer exists, no
-- sync answer or lapse is left without its area, and no share is left
-- without its consent row (consent_id is not a foreign key).
create function th914a_test.no_orphans(p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  col record;
  n bigint;
  total bigint := 0;
begin
  for col in
    select a.attrelid::regclass as rel
    from pg_catalog.pg_attribute as a
    join pg_catalog.pg_class as c on c.oid = a.attrelid
    where c.relnamespace = 'public'::regnamespace and c.relkind = 'r'
      and a.attname = 'enrolment_id' and not a.attisdropped
  loop
    execute pg_catalog.format(
      'select count(*) from %s as t where t.enrolment_id is not null
         and not exists (select 1 from public.enrolments as e where e.id = t.enrolment_id)', col.rel)
    into n;
    total := total + n;
  end loop;
  total := total
    + (select count(*) from public.sync_answer as s
       where not exists (select 1 from public.sync_area as a
                         where a.user_id = s.user_id and a.programme_code = s.programme_code))
    + (select count(*) from public.sync_lapse as s
       where not exists (select 1 from public.sync_area as a
                         where a.user_id = s.user_id and a.programme_code = s.programme_code))
    + (select count(*) from public.care_shares as s
       where not exists (select 1 from public.programme_consents as c where c.id = s.consent_id));
  perform th914a_test.ok(total = 0,
    'no row references a deleted enrolment and no share is left without its consent: ' || p_label);
end;
$f$;

-- After every scenario: B is unchanged and nothing is orphaned.
create function th914a_test.after(p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  perform th914a_test.ok(
    th914a_test.state('00000000-0000-4000-8000-00000914a0b1') = th914a_test.v('b_seeded')::jsonb
    and (select pg_catalog.string_agg(programme_code || ':' || status, ',' order by programme_code)
         from public.enrolments where user_id = '00000000-0000-4000-8000-00000914a0b1')
        = th914a_test.v('b_statuses')
    and (select programme_codes from public.supporters
         where user_id = '00000000-0000-4000-8000-00000914a0b1') = '{bf}'::text[],
    'B is unchanged: ' || p_label);
  perform th914a_test.no_orphans(p_label);
end;
$f$;

-- A synthetic member p_user (key p_key) enrolled in bf, hw, st, sd, ck, ca and
-- ea, each with a core consent and a sync area, answer and lapse; a quit plan;
-- Heartwise, Steady and ClearAir program data; a supporter listing bf; an
-- account consent; a Stride caregiver with its consent and an event; a clinic
-- connection with a Checkup sharing consent, a share, an access row and a
-- message attaching the share; and a message tied to no programme. Enrolment
-- ids are stored as th914a.<p_key>_<code>.
create function th914a_test.seed(p_user uuid, p_key text, p_org uuid)
returns void language plpgsql set search_path = '' as $f$
declare
  code text;
  enrolment uuid;
  connection uuid;
  caregiver uuid;
  share_consent uuid;
  share uuid;
begin
  insert into auth.users (id, email, aud, role) values
    (p_user, 'synthetic-' || p_key || '-914a@example.test', 'authenticated', 'authenticated');
  insert into public.quit_plans (user_id, quit_date) values (p_user, current_date);
  insert into public.program_data (user_id, program_id, payload) values
    (p_user, 'heartwise', '{}'), (p_user, 'steady', '{}'), (p_user, 'clearair', '{}');
  insert into public.account_consents (user_id, purpose, consent_version, locale)
  values (p_user, 'essential', 'v1-draft', 'en');
  insert into public.sync_account (user_id) values (p_user);
  foreach code in array array['bf', 'hw', 'st', 'sd', 'ck', 'ca', 'ea'] loop
    insert into public.enrolments (user_id, programme_code, status)
    values (p_user, code, case when code = 'hw' then 'focus' else 'learn_only' end)
    returning id into enrolment;
    perform pg_catalog.set_config('th914a.' || p_key || '_' || code, enrolment::text, true);
    insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
    values (enrolment, 'core', 'v1-draft', 'en');
    insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
    values (p_user, enrolment, code, 1, 1);
    insert into public.sync_answer (user_id, programme_code, screen_id, payload)
    values (p_user, code, code || '_q1', '{"answer": 1}');
    insert into public.sync_lapse (user_id, programme_code, ordinal, at)
    values (p_user, code, 0, pg_catalog.now());
  end loop;
  insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
  values (th914a_test.v(p_key || '_hw')::uuid, 'reminders', 'v1-draft', 'en');
  insert into public.supporters (user_id, name, phone, programme_codes)
  values (p_user, 'Synthetic Supporter', '+15550109141', '{bf}');
  -- Stride: caregiver, its sharing consent and an event.
  insert into public.caregivers (user_id, enrolment_id, name, phone)
  values (p_user, th914a_test.v(p_key || '_sd')::uuid, 'Synthetic Caregiver', '+15550109142')
  returning id into caregiver;
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (th914a_test.v(p_key || '_sd')::uuid, 'share_caregiver', caregiver::text, 'v1-draft', 'en');
  insert into public.caregiver_events (user_id, caregiver_id, kind, occurred_at)
  values (p_user, caregiver, 'sd.session_finished', pg_catalog.now());
  -- Checkup: connection, sharing consent, share, access row, attached message.
  insert into public.care_connections (user_id, org_id) values (p_user, p_org) returning id into connection;
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (th914a_test.v(p_key || '_ck')::uuid, 'share_care_team', connection::text, 'v1-draft', 'en')
  returning id into share_consent;
  insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
  values (p_user, th914a_test.v(p_key || '_ck')::uuid, connection, share_consent, 'message_attachment',
          '{"summary": "synthetic"}')
  returning id into share;
  insert into public.care_share_access (user_id, share_id, channel) values (p_user, share, 'secure_link');
  insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
  values (p_user, connection, th914a_test.v(p_key || '_ck')::uuid, 'Synthetic topic',
          'Synthetic attached message', share);
  insert into public.care_messages (user_id, connection_id, topic, body)
  values (p_user, connection, 'Synthetic topic', 'Synthetic message for no programme');
end;
$f$;

grant usage on schema th914a_test to public;
grant execute on all functions in schema th914a_test to public;
revoke all on function th914a_test.seed(uuid, text, uuid) from public;

-- Catalogue ---------------------------------------------------------------------------
create role th914a_plain nologin;
select th914a_test.ok(
  not pg_catalog.has_table_privilege('authenticated', 'public.enrolments', 'DELETE')
  and not pg_catalog.has_table_privilege('anon', 'public.enrolments', 'DELETE')
  and not pg_catalog.has_table_privilege('thsync', 'public.enrolments', 'DELETE')
  and not pg_catalog.has_table_privilege('service_role', 'public.enrolments', 'DELETE')
  and not pg_catalog.has_table_privilege('th914a_plain', 'public.enrolments', 'DELETE'),
  'catalogue: authenticated, anon, thsync, service_role and a role with only PUBLIC hold no DELETE on enrolments');
select th914a_test.ok(
  (select pg_catalog.string_agg(policyname || ':' || cmd, ',' order by policyname)
   from pg_catalog.pg_policies where schemaname = 'public' and tablename = 'enrolments')
  = 'enrolments_insert_own:INSERT,enrolments_select_own:SELECT,enrolments_update_own:UPDATE',
  'catalogue: enrolments has no delete policy (select, insert and update only)');
select th914a_test.ok(
  (select with_check ~ '^\(\(\( SELECT auth\.uid\(\) AS uid\) = user_id\) AND (public\.)?deletion_barrier_open\(\) AND \(NOT (public\.)?sync_writer_session\(\)\)\)$'
     and qual !~ 'deletion_barrier_open'
     and qual ~ ' AND \(NOT (public\.)?sync_writer_session\(\)\)\)$'
     and roles = '{authenticated}'::name[]
   from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'enrolments' and policyname = 'enrolments_update_own'),
  'catalogue: the update policy checks the deletion barrier before the sync guard in its with check; its using clause has no barrier');
select th914a_test.ok(
  (select p.prosecdef and p.proconfig = array['search_path=""']
     and p.prorettype = 'jsonb'::regtype and p.provolatile = 'v'
   from pg_catalog.pg_proc as p where p.oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure),
  'catalogue: delete_enrolment_now is security definer with an empty search_path and returns jsonb');
select th914a_test.ok(
  (select proowner from pg_catalog.pg_proc where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure)
  = (select proowner from pg_catalog.pg_proc where oid = 'public.delete_my_account(text)'::regprocedure),
  'catalogue: delete_enrolment_now has the owner of delete_my_account');
select th914a_test.ok(
  (select pg_catalog.string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ','
                                order by a.grantee::regrole::text)
   from pg_catalog.pg_proc as p
   cross join lateral pg_catalog.aclexplode(
     coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
   where p.oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure)
  = (select pg_catalog.string_agg(x, ',' order by x)
     from pg_catalog.unnest(array[
       (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
        where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure) || ':EXECUTE',
       'authenticated:EXECUTE']) as x),
  'catalogue: only its owner and authenticated may execute delete_enrolment_now; no PUBLIC entry');
select th914a_test.ok(
  not pg_catalog.has_function_privilege('anon', 'public.delete_enrolment_now(uuid,text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('service_role', 'public.delete_enrolment_now(uuid,text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('th914a_plain', 'public.delete_enrolment_now(uuid,text)', 'EXECUTE'),
  'catalogue: anon, service_role and a role with only PUBLIC may not execute delete_enrolment_now');

-- Synthetic members (as the superuser) -----------------------------------------------
insert into public.care_orgs (name) values ('Synthetic Clinic 914a');
select set_config('th914a.org', id::text, true) from public.care_orgs where name = 'Synthetic Clinic 914a';
select th914a_test.seed('00000000-0000-4000-8000-00000914a0a1', 'a', th914a_test.v('org')::uuid);
select th914a_test.seed('00000000-0000-4000-8000-00000914a0b1', 'b', th914a_test.v('org')::uuid);
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
select set_config('th914a.a_seeded', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.b_seeded', th914a_test.state('00000000-0000-4000-8000-00000914a0b1')::text, true);
select set_config('th914a.b_statuses', (
  select string_agg(programme_code || ':' || status, ',' order by programme_code)
  from public.enrolments where user_id = '00000000-0000-4000-8000-00000914a0b1'), true);
select th914a_test.ok(
  th914a_test.v('a_seeded')::jsonb @> '{"profiles": 1, "quit_plans": 1, "program_data": 3,
    "enrolments": 7, "programme_consents": 10, "account_consents": 1, "sync_answers": 7,
    "sync_lapses": 7, "sync_areas": 7, "sync_accounts": 1, "care_share_access": 1,
    "care_messages": 2, "care_shares": 1, "caregiver_events": 1, "caregivers": 1,
    "care_connections": 1, "supporters": 1, "users": 1}'::jsonb
  and th914a_test.v('b_seeded')::jsonb = th914a_test.v('a_seeded')::jsonb,
  'setup: A and B each hold 7 enrolments with their consents, sync rows and care rows, a quit plan, three program data rows and account data');
select th914a_test.ok(
  th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_hw')::uuid, 'hw')
    @> '{"quit_plans": 0, "program_data": 1, "enrolments": 1, "programme_consents": 2,
         "sync_answers": 1, "sync_lapses": 1, "sync_areas": 1, "care_share_access": 0,
         "care_messages": 0, "care_shares": 0, "caregiver_events": 0, "caregivers": 0}'::jsonb
  and th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_bf')::uuid, 'bf')
    @> '{"quit_plans": 1, "program_data": 0, "enrolments": 1, "programme_consents": 1}'::jsonb
  and th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_sd')::uuid, 'sd')
    @> '{"programme_consents": 2, "caregivers": 1, "caregiver_events": 1}'::jsonb
  and th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_ck')::uuid, 'ck')
    @> '{"programme_consents": 2, "care_shares": 1, "care_share_access": 1, "care_messages": 1}'::jsonb
  and th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_st')::uuid, 'st')
    @> '{"program_data": 1}'::jsonb
  and th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1', th914a_test.v('a_ca')::uuid, 'ca')
    @> '{"program_data": 1}'::jsonb,
  'setup: the count helper sees each programme''s rows (hw, bf, sd, ck, st, ca)');
select th914a_test.no_orphans('setup');

-- Refusals: nothing is deleted ----------------------------------------------------------
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'delete from public.enrolments where id = %L', th914a_test.v('a_hw')),
  '42501', '%permission denied%', 'A API, recent sign-in: a direct delete of its own enrolment is refused');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)), 'anon');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  '42501', 'permission denied for function delete_enrolment_now', 'anon may not execute delete_enrolment_now');
select th914a_test.act_as('authenticator', th914a_test.claims(null, th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  '42501', 'Authentication required', 'no caller is refused (42501)');
select th914a_test.act_as('thsync',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.ok(session_user = 'thsync' and current_user = 'authenticated' and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH010', 'The sync service writes only sync tables', 'A sync session is refused (TH010)',
  'sync_session_refused');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''delete'')', th914a_test.v('a_hw')),
  'TH010', 'The sync service writes only sync tables',
  'A sync session with a wrong confirmation: the sync refusal comes first', 'sync_session_refused');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''delete'')', th914a_test.v('a_hw')),
  '23514', 'Explicit confirmation required', 'A API: confirmation ''delete'' is refused (23514)');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, null)', th914a_test.v('a_hw')),
  '23514', 'Explicit confirmation required', 'A API: a null confirmation is refused (23514)');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(601)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''delete'')', th914a_test.v('a_hw')),
  '23514', 'Explicit confirmation required',
  'A API, stale sign-in and a wrong confirmation: the confirmation check comes first');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH017', 'Recent authentication is required', 'A API: a sign-in 601 s old is refused (TH017)',
  'recent_authentication_required');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', gen_random_uuid()),
  'TH017', 'Recent authentication is required',
  'A API, stale sign-in and an unknown enrolment: the sign-in check comes before the lookup',
  'recent_authentication_required');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(-61)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH017', 'Recent authentication is required', 'A API: a sign-in 61 s in the future is refused (TH017)',
  'recent_authentication_required');
select th914a_test.act_as('authenticator', th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', null));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH017', 'Recent authentication is required', 'A API: a token without amr is refused (TH017)',
  'recent_authentication_required');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', '"password"'::jsonb));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH017', 'Recent authentication is required', 'A API: an amr that is not an array is refused (TH017)',
  'recent_authentication_required');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', (extract(epoch from now()) - 30)::text))));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH017', 'Recent authentication is required', 'A API: an amr timestamp that is a string is refused (TH017)',
  'recent_authentication_required');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0b1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH012', 'Enrolment not found', 'B API: A''s enrolment id is refused (TH012)', 'enrolment_not_found');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', gen_random_uuid()),
  'TH012', 'Enrolment not found', 'A API: a random enrolment id is refused (TH012)', 'enrolment_not_found');
select th914a_test.refused('select public.delete_enrolment_now(null, ''DELETE'')',
  'TH012', 'Enrolment not found', 'A API: a null enrolment id is refused (TH012)', 'enrolment_not_found');

-- Owner check: the owner switched to a role that does not bypass row-level
-- security, inside this transaction, then restored.
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select set_config('th914a.owner', (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
  where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure), true);
select set_config('th914a.acl', (select proacl::text from pg_catalog.pg_proc
  where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure), true);
create role th914a_nobypass nologin;
grant usage on schema public, auth to th914a_nobypass;
grant execute on function auth.uid(), auth.jwt(), public.sync_writer_session() to th914a_nobypass;
alter function public.delete_enrolment_now(uuid, text) owner to th914a_nobypass;
select th914a_test.ok(
  (select not rolsuper and not rolbypassrls from pg_catalog.pg_roles where rolname = 'th914a_nobypass')
  and (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
       where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure) = 'th914a_nobypass',
  'owner check: delete_enrolment_now is now owned by a role that is not a superuser and does not bypass row-level security');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH020', 'Account deletion requires a function owner that bypasses row-level security',
  'owner check: an owner that does not bypass row-level security is refused (TH020)', 'rls_bypass_required');
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', gen_random_uuid()),
  'TH020', 'Account deletion requires a function owner that bypasses row-level security',
  'owner check: the owner check comes before the lookup', 'rls_bypass_required');
select th914a_test.act_as(current_setting('th914a.superuser'), null);
do $restore$
begin
  execute pg_catalog.format('alter function public.delete_enrolment_now(uuid, text) owner to %I',
    pg_catalog.current_setting('th914a.owner'));
end;
$restore$;
select th914a_test.ok(
  (select pg_catalog.pg_get_userbyid(proowner) = current_setting('th914a.owner')
          and proacl::text = current_setting('th914a.acl')
   from pg_catalog.pg_proc where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure),
  'owner check: the owner and privileges are restored');

select th914a_test.ok(
  th914a_test.state('00000000-0000-4000-8000-00000914a0a1') = th914a_test.v('a_seeded')::jsonb
  and (select programme_codes from public.supporters
       where user_id = '00000000-0000-4000-8000-00000914a0a1') = '{bf}'::text[],
  'A: every refusal deleted nothing');
select th914a_test.after('refusals');

-- Heartwise -----------------------------------------------------------------------------
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_hw')::uuid, 'hw')::text, true);
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_hw')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb,
  'A Heartwise: the receipt equals the rows held for Heartwise, one count per table');
select th914a_test.ok(
  th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_hw')::uuid, 'hw'))
  and (select count(*) from public.program_data
       where user_id = '00000000-0000-4000-8000-00000914a0a1' and program_id = 'heartwise') = 0
  and (select count(*) from public.program_data
       where user_id = '00000000-0000-4000-8000-00000914a0a1' and program_id = 'steady') = 1,
  'A Heartwise: its enrolment, consents, sync rows and Heartwise program data are gone; Steady program data is kept');
select th914a_test.ok(
  th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
  = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A Heartwise: nothing else of A changed');
select th914a_test.after('Heartwise');

-- BreatheFree: the quit plan; the supporter only loses bf ----------------------------------
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_bf')::uuid, 'bf')::text, true);
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_bf')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb
  and (th914a_test.v('receipt')::jsonb ->> 'quit_plans')::int = 1,
  'A BreatheFree: the receipt equals the rows held for BreatheFree, the quit plan included');
select th914a_test.ok(
  th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_bf')::uuid, 'bf'))
  and (select count(*) from public.quit_plans where user_id = '00000000-0000-4000-8000-00000914a0a1') = 0
  and (select programme_codes from public.supporters
       where user_id = '00000000-0000-4000-8000-00000914a0a1') = '{}'::text[],
  'A BreatheFree: the quit plan is gone; the supporter keeps its row and loses bf');
select th914a_test.ok(
  th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
  = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A BreatheFree: nothing else of A changed');
select th914a_test.after('BreatheFree');

-- Stride: caregiver and event ------------------------------------------------------------
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_sd')::uuid, 'sd')::text, true);
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_sd')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb
  and (th914a_test.v('receipt')::jsonb ->> 'caregivers')::int = 1
  and (th914a_test.v('receipt')::jsonb ->> 'caregiver_events')::int = 1,
  'A Stride: the receipt equals the rows held for Stride, caregiver and event included');
select th914a_test.ok(
  th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_sd')::uuid, 'sd'))
  and th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
      = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A Stride: the caregiver, its event and consent are gone; nothing else of A changed');
select th914a_test.after('Stride');

-- Checkup: share, access row and attached message; the connection stays ------------------------
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_ck')::uuid, 'ck')::text, true);
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_ck')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb
  and (th914a_test.v('receipt')::jsonb ->> 'care_shares')::int = 1
  and (th914a_test.v('receipt')::jsonb ->> 'care_share_access')::int = 1
  and (th914a_test.v('receipt')::jsonb ->> 'care_messages')::int = 1,
  'A Checkup: the receipt equals the rows held for Checkup, share, access row and attached message included');
select th914a_test.ok(
  th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_ck')::uuid, 'ck'))
  and (select count(*) from public.care_connections
       where user_id = '00000000-0000-4000-8000-00000914a0a1' and revoked_at is null) = 1
  and (select count(*) from public.care_messages
       where user_id = '00000000-0000-4000-8000-00000914a0a1' and enrolment_id is null) = 1
  and th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
      = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A Checkup: the share, access row, attached message and consents are gone; the connection and the message for no programme stay');
select th914a_test.after('Checkup');

-- A left enrolment (Steady) -------------------------------------------------------------
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
update public.enrolments set status = 'left' where id = th914a_test.v('a_st')::uuid;
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_st')::uuid, 'st')::text, true);
select th914a_test.ok(
  (select status = 'left' from public.enrolments where id = th914a_test.v('a_st')::uuid)
  and (th914a_test.v('expected')::jsonb ->> 'program_data')::int = 1,
  'A Steady: left, with its Steady program data');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_st')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb
  and th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_st')::uuid, 'st'))
  and th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
      = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A Steady: a left enrolment is deleted with its data; nothing else of A changed');
select th914a_test.after('left Steady');

-- A repeat finds nothing ------------------------------------------------------------------
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select th914a_test.refused(pg_catalog.format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th914a_test.v('a_hw')),
  'TH012', 'Enrolment not found', 'A API: a repeat for a deleted enrolment is refused (TH012)',
  'enrolment_not_found');
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.state('00000000-0000-4000-8000-00000914a0a1') = th914a_test.v('a_before')::jsonb,
  'A: the repeat deleted nothing');
select th914a_test.after('repeat');

-- After account deletion has started: no update, delete-now still works ----------------------
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
update public.enrolments set status = 'left' where id = th914a_test.v('a_ea')::uuid;
select th914a_test.ok(public.begin_account_deletion('DELETE'), 'A API: begin_account_deletion sets the barrier');
select th914a_test.refused(pg_catalog.format(
  'update public.enrolments set status = ''learn_only'' where id = %L', th914a_test.v('a_ea')),
  '42501', '%row-level security%', 'A API, deletion started: rejoining a left programme is refused (42501)');
select th914a_test.refused(pg_catalog.format(
  'update public.enrolments set status = ''paused'' where id = %L', th914a_test.v('a_ca')),
  '42501', '%row-level security%', 'A API, deletion started: pausing a programme is refused (42501)');
select th914a_test.refused(pg_catalog.format(
  'update public.enrolments set mode = null where id = %L', th914a_test.v('a_ca')),
  '42501', '%row-level security%', 'A API, deletion started: any other enrolment update is refused (42501)');
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select set_config('th914a.a_before', th914a_test.state('00000000-0000-4000-8000-00000914a0a1')::text, true);
select set_config('th914a.expected', th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
  th914a_test.v('a_ca')::uuid, 'ca')::text, true);
select th914a_test.ok(
  (select status from public.enrolments where id = th914a_test.v('a_ea')::uuid) = 'left'
  and (select status from public.enrolments where id = th914a_test.v('a_ca')::uuid) = 'learn_only'
  and (select account_deletion_started_at is not null from public.profiles
       where id = '00000000-0000-4000-8000-00000914a0a1'),
  'A: the refused updates changed no enrolment; deletion has started');
select th914a_test.act_as('authenticator',
  th914a_test.claims('00000000-0000-4000-8000-00000914a0a1', th914a_test.amr_at(30)));
select set_config('th914a.receipt', public.delete_enrolment_now(th914a_test.v('a_ca')::uuid, 'DELETE')::text, true);
select th914a_test.act_as(current_setting('th914a.superuser'), null);
select th914a_test.ok(
  th914a_test.v('receipt')::jsonb = th914a_test.v('expected')::jsonb
  and (th914a_test.v('receipt')::jsonb ->> 'program_data')::int = 1
  and th914a_test.all_zero(th914a_test.rows_for('00000000-0000-4000-8000-00000914a0a1',
    th914a_test.v('a_ca')::uuid, 'ca'))
  and th914a_test.state('00000000-0000-4000-8000-00000914a0a1')
      = th914a_test.minus(th914a_test.v('a_before')::jsonb, th914a_test.v('receipt')::jsonb),
  'A ClearAir, deletion started: delete-now still deletes the enrolment and its ClearAir program data');
select th914a_test.after('after deletion started');

-- Account data stays ------------------------------------------------------------------------
select th914a_test.ok(
  (select string_agg(programme_code, ',' order by programme_code) from public.enrolments
   where user_id = '00000000-0000-4000-8000-00000914a0a1') = 'ea'
  and th914a_test.state('00000000-0000-4000-8000-00000914a0a1') @> '{"profiles": 1, "account_consents": 1,
    "sync_accounts": 1, "care_connections": 1, "care_messages": 1, "supporters": 1, "users": 1}'::jsonb,
  'A: only the Ease enrolment is left; the profile, account consent, sync account, connection, message for no programme and supporter stay');

select 'TH914A_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

print_control_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'CONTROL setup: this control needs a superuser connection';
  end if;
end;
$setup$;

create schema th914a_control;

-- Synthetic C with one enrolment and its core consent.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000914a0c1', 'synthetic-control-914a@example.test', 'authenticated', 'authenticated');
insert into public.enrolments (id, user_id, programme_code, status) values
  ('00000000-0000-4000-8000-00000914ae01', '00000000-0000-4000-8000-00000914a0c1', 'hw', 'focus');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-00000914ae01', 'core', 'v1-draft', 'en');

-- As authenticated with a recent sign-in, C deletes its own enrolment
-- directly. The outcome is "completed" or the SQLSTATE that refused it.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000914a0c1', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
set local role authenticated;
do $c$
declare
  outcome text;
  n integer;
begin
  begin
    delete from public.enrolments where id = '00000000-0000-4000-8000-00000914ae01';
    get diagnostics n = row_count;
    outcome := 'completed:' || n;
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th914ac.outcome', outcome, true);
  raise notice 'CONTROL direct delete of an own enrolment: %', outcome;
end;
$c$;
reset role;
select set_config('request.jwt.claims', '', true);

select set_config('th914ac.remaining', (
  select count(*)::text from public.enrolments where id = '00000000-0000-4000-8000-00000914ae01'), true);
do $report$
begin
  raise notice 'CONTROL remaining enrolment rows of C: %', pg_catalog.current_setting('th914ac.remaining');
end;
$report$;

select case
  when current_setting('th914ac.outcome') = '42501' and current_setting('th914ac.remaining') = '1'
    then 'TH914A_CONTROL_DIRECT_DELETE_REFUSED'
  when current_setting('th914ac.outcome') = 'completed:1' and current_setting('th914ac.remaining') = '0'
    then 'TH914A_CONTROL_DIRECT_DELETE_COMPLETED'
  else 'TH914A_CONTROL_UNEXPECTED'
end as result;
rollback;
SQL
}

case "${1:-}" in
  --print-sql)
    print_sql
    exit 0
    ;;
  --print-control-sql)
    print_control_sql
    exit 0
    ;;
esac

fail() {
  echo "Enrolment delete-now check failed: $1" >&2
  exit 1
}

# Accepts only postgres:// or postgresql:// URLs whose whole authority is
# [userinfo@]127.0.0.1|localhost[:port] (same rule as the other verify scripts).
url_shape='^postgres(ql)?://([^/]*)(/[^?#[:space:]]*)?$'
local_authority='^([^@/?#,[:space:]]*@)?(127\.0\.0\.1|localhost)(:[0-9]{1,5})?$'
db_url_is_local() {
  [[ "$1" =~ $url_shape ]] || return 1
  [[ "${BASH_REMATCH[2]}" =~ $local_authority ]]
}
db_url_is_local 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' ||
  fail 'local URL guard rejects a local URL'
for u in 'postgresql://postgres@db.example.test:5432/postgres' \
  'postgresql://postgres@localhost:54322/postgres?host=db.example.test' \
  'postgresql://u@db.example.test:5432@127.0.0.1/postgres'; do
  if db_url_is_local "$u"; then fail "local URL guard accepts a non-local URL ($u)"; fi
done
if [[ -n "${VERIFY_DB_URL:-}" ]] && ! db_url_is_local "$VERIFY_DB_URL"; then
  fail 'VERIFY_DB_URL must point at a local database (127.0.0.1 or localhost)'
fi

for f in "$migration" "$sign_in_source" "$owner_check_source" "$contract"; do
  [[ -f "$f" ]] || fail "missing $f"
done
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

# Name and version ------------------------------------------------------------------------
[[ "${migration##*/}" =~ ^[0-9]{12}_[a-z0-9_]+\.sql$ ]] ||
  fail "${migration##*/} is not YYYYMMDDNNNN_name.sql"
[[ "${migration##*/}" == 202610180012_enrolment_delete_now.sql ]] ||
  fail "the migration is 202610180012_enrolment_delete_now.sql"

migration_files=()
while IFS= read -r -d '' path; do
  migration_files+=("$path")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -name '*.sql' -print0 | LC_ALL=C sort -z)

# The SQL on stdin as one statement per line: comments removed, lower case,
# double quotes dropped, whitespace collapsed to single spaces, split at ";".
statements() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' |
    sed -E 's/ +/ /g' | tr ';' '\n' | sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}

# One definition, in this migration -------------------------------------------------------
defined_in=$(grep -Eil '^create (or replace )?function +("?public"?\.)?"?delete_enrolment_now"? *\(' "${migration_files[@]}" || true)
first_defined=$(head -n 1 <<<"$defined_in")
[[ "$first_defined" == "$migration" ]] ||
  fail "public.delete_enrolment_now must first be defined in $migration (found in: ${defined_in:-nothing})"
[[ "$(grep -Eic '^create (or replace )?function +("?public"?\.)?"?delete_enrolment_now"? *\(' "$migration")" -eq 1 ]] ||
  fail 'public.delete_enrolment_now must be defined exactly once in the migration'

# The migration, with the function body replaced by "body": exactly these
# statements, in this order.
outline=$(awk '
  /^as \$\$$/ { print "as body"; skip = 1; next }
  skip && /^\$\$;$/ { print ";"; skip = 0; next }
  !skip { print }
' "$migration" | statements)
expected_outline="begin
drop policy enrolments_delete_own on public.enrolments
revoke delete on table public.enrolments from public, anon, authenticated
drop policy enrolments_update_own on public.enrolments
create policy enrolments_update_own on public.enrolments for update to authenticated using ((select auth.uid()) = user_id and not public.sync_writer_session()) with check ( (select auth.uid()) = user_id and public.deletion_barrier_open() and not public.sync_writer_session() )
create function public.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text) returns jsonb language plpgsql security definer set search_path = '' as body
revoke all on function public.delete_enrolment_now(uuid, text) from public, anon, authenticated, service_role
grant execute on function public.delete_enrolment_now(uuid, text) to authenticated
commit"
[[ "$outline" == "$expected_outline" ]] ||
  fail "$migration must contain exactly: drop of enrolments_delete_own, revoke of DELETE on enrolments from public, anon and authenticated, the update policy re-created with the deletion barrier before the sync guard, the function (security definer, search_path ''), the revoke from public, anon, authenticated and service_role and the grant to authenticated. Got:
$outline"
# The update policy keeps the multi-line form of enrolments_insert_own, which
# the sync-guard policy parser reads.
grep -Fxq '  public.deletion_barrier_open() and' "$migration" ||
  fail 'the update policy must name public.deletion_barrier_open() on its own line in its with check'

# Account deletion functions are not named, not even in a comment.
if grep -Eq 'delete_my_app_data|delete_my_account|begin_account_deletion' "$migration"; then
  fail "$migration must not name delete_my_app_data, delete_my_account or begin_account_deletion"
fi

# Body order --------------------------------------------------------------------------------
body=$(sed -n '/^create function public\.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)$/,/^\$\$;$/p' "$migration")
[[ -n "$body" ]] ||
  fail 'the function must start with "create function public.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)" and end with "$$;"'

# The recent sign-in check, from its opening comment to the end if after its
# TH017 raise, and the owner check, from its opening comment to its end if.
sign_in_block() {
  awk '
    /^  -- Recent sign-in: the newest amr entry/ { on = 1 }
    on { print }
    on && /^  end if;$/ { exit }
  ' <<<"$1"
}
owner_block() {
  awk '
    /^  -- The checks and deletes below run as the function owner and must see$/ { on = 1 }
    on { print }
    on && /^  end if;$/ { exit }
  ' <<<"$1"
}
reference_sign_in=$(sed -n '39,55p' "$sign_in_source")
reference_owner=$(sed -n '73,82p' "$owner_check_source")
[[ "$(head -n 1 <<<"$reference_sign_in")" == '  -- Recent sign-in: the newest amr entry with a string method and a numeric' ]] ||
  fail "$sign_in_source lines 39-55 are not the recent sign-in check"
[[ "$(head -n 1 <<<"$reference_owner")" == '  -- The checks and deletes below run as the function owner and must see' ]] ||
  fail "$owner_check_source lines 73-82 are not the owner check"
[[ "$(sign_in_block "$body")" == "$reference_sign_in" ]] ||
  fail "the recent sign-in check must be identical to $sign_in_source lines 39-55"
[[ "$(owner_block "$body")" == "$reference_owner" ]] ||
  fail "the owner check must be identical to $owner_check_source lines 73-82"

# shellcheck disable=SC2001  # per-line comment removal, not one substitution
code=$(sed 's/--.*$//' <<<"$body")
line_of() {
  local found count
  found=$(grep -nE -- "$1" <<<"$code" || true)
  count=$(grep -c . <<<"$found" || true)
  [[ "$count" -eq 1 ]] || fail "delete_enrolment_now must contain exactly one line matching /$1/ (found $count)"
  echo "${found%%:*}"
}
next_line_matches() {
  grep -Eq -- "$2" <<<"$(sed -n "$(($1 + 1))p" <<<"$code")" || fail "delete_enrolment_now: $3"
}
l_caller=$(line_of "^  caller_id uuid := auth\\.uid\\(\\);$")
l_null=$(line_of "^  if caller_id is null then$")
next_line_matches "$l_null" "^    raise insufficient_privilege using message = 'Authentication required';$" \
  'no caller must raise insufficient_privilege (42501)'
l_sync=$(line_of "^  if public\\.sync_writer_session\\(\\) then$")
next_line_matches "$l_sync" "^    raise exception using errcode = 'TH010',$" 'a sync session must raise TH010 directly'
next_line_matches "$((l_sync + 1))" "^      message = 'The sync service writes only sync tables',$" 'TH010 must carry its registered message'
next_line_matches "$((l_sync + 2))" "^      hint = 'sync_session_refused';$" 'TH010 must carry its registered hint'
l_confirm=$(line_of "^  if p_confirmation is distinct from 'DELETE' then$")
next_line_matches "$l_confirm" "^    raise check_violation using message = 'Explicit confirmation required';$" \
  'a wrong confirmation must raise check_violation (23514)'
l_amr=$(line_of "auth\\.jwt\\(\\) -> 'amr'\\) = 'array'$")
l_th017=$(line_of "errcode = 'TH017',$")
l_guard=$(line_of "^    where r\\.rolname = current_user and \\(r\\.rolsuper or r\\.rolbypassrls\\)$")
l_th020=$(line_of "errcode = 'TH020',$")
l_lookup=$(line_of "^  select e\\.programme_code$")
next_line_matches "$l_lookup" "^  into v_programme_code$" 'the lookup reads the programme code into v_programme_code'
next_line_matches "$((l_lookup + 1))" "^  from public\\.enrolments as e$" 'the lookup reads public.enrolments'
next_line_matches "$((l_lookup + 2))" "^  where e\\.id = p_enrolment_id$" 'the lookup is by enrolment id'
next_line_matches "$((l_lookup + 3))" "^    and e\\.user_id = caller_id$" 'the lookup is limited to the caller'
next_line_matches "$((l_lookup + 4))" "^  for update;$" 'the lookup locks the enrolment row'
next_line_matches "$((l_lookup + 5))" "^  if not found then$" 'no enrolment of the caller must be refused'
next_line_matches "$((l_lookup + 6))" "^    raise exception using errcode = 'TH012',$" 'no enrolment of the caller must raise TH012'
next_line_matches "$((l_lookup + 7))" "^      message = 'Enrolment not found',$" 'TH012 must carry its registered message'
next_line_matches "$((l_lookup + 8))" "^      hint = 'enrolment_not_found';$" 'TH012 must carry its registered hint'
l_th012=$((l_lookup + 6))

# The deletes, in this order, each counted directly after it and each limited
# to the caller's rows.
deletes=(care_share_access care_messages care_shares caregiver_events caregivers sync_lapse sync_answer
  sync_area programme_consents quit_plans program_data enrolments)
keys=(care_share_access care_messages care_shares caregiver_events caregivers sync_lapses sync_answers
  sync_areas programme_consents quit_plans program_data enrolments)
order=("$l_caller" "$l_null" "$l_sync" "$l_confirm" "$l_amr" "$l_th017" "$l_guard" "$l_th020" "$l_lookup" "$l_th012")
for ((i = 0; i < ${#deletes[@]}; i++)); do
  l_del=$(line_of "^ +delete from public\\.${deletes[i]}( |$)")
  l_count=$(line_of "^ +get diagnostics deleted_${keys[i]} = row_count;$")
  order+=("$l_del" "$l_count")
  stmt=$(sed -n "${l_del},${l_count}p" <<<"$code" | tr '\n' ' ' | sed -E 's/ +/ /g')
  case "${deletes[i]}" in
    programme_consents)
      [[ "$stmt" == *"where enrolment_id = p_enrolment_id and enrolment_id in (select id from public.enrolments where user_id = caller_id);"* ]] ||
        fail "the programme_consents delete must be limited to the enrolment and to the caller's enrolments" ;;
    *)
      [[ "$stmt" == *"where user_id = caller_id"* ]] || fail "the ${deletes[i]} delete must be limited to user_id = caller_id" ;;
  esac
done
l_bf=$(line_of "^  if v_programme_code = 'bf' then$")
l_quit=$(line_of "^ +delete from public\\.quit_plans( |$)")
((l_quit == l_bf + 1)) || fail 'the quit plan is deleted only for BreatheFree'
line_of "^    and program_id = \\(select p\\.slug from public\\.programmes as p where p\\.code = v_programme_code\\);$" >/dev/null
line_of "^  where user_id = caller_id and id = p_enrolment_id;$" >/dev/null
l_return=$(line_of "^  return jsonb_build_object\\($")
order+=("$l_return")
for ((i = 1; i < ${#order[@]}; i++)); do
  ((order[i - 1] < order[i])) ||
    fail 'delete_enrolment_now must run: caller, no caller (42501), sync refusal (TH010), confirmation (23514), recent sign-in (TH017), owner bypasses row-level security (TH020), the locked lookup (TH012), then the deletes in order, each counted, then the receipt'
done
[[ "$(grep -cE '(^|[^a-z_])delete +from' <<<"$code")" -eq 12 ]] || fail 'delete_enrolment_now deletes from exactly 12 tables'
# The lookup's "for update" is a row lock, not a write.
writes=$(grep -vxF '  for update;' <<<"$code")
first_write=$(grep -nE '(^|[^a-z_])(delete|truncate|update|insert)([^a-z_]|$)' <<<"$writes" | head -n 1 | cut -d: -f1)
((first_write > l_th012 - 1)) || fail 'delete_enrolment_now must not write before its checks'
if grep -Eiq '(^|[^a-z_])(execute|update|insert|truncate|set +role|set +session|perform)([^a-z_]|$)|request\.jwt|deletion_barrier_open|account_deletion_started_at' <<<"$writes"; then
  fail 'delete_enrolment_now runs no dynamic SQL, writes nothing but its deletes, changes no role, reads the token only through auth.uid() and auth.jwt(), and does not check the deletion barrier'
fi

# The receipt: exactly 12 keys, one per line, named as in the account receipt,
# the last without a trailing comma.
receipt=$(sed -n '/^  return jsonb_build_object($/,/^  );$/p' <<<"$code" | sed '1d;$d')
expected_receipt="    'quit_plans', deleted_quit_plans,
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
    'caregivers', deleted_caregivers"
[[ "$receipt" == "$expected_receipt" ]] ||
  fail "delete_enrolment_now must return exactly the 12 receipt keys, one per line, the last without a trailing comma. Got:
$receipt"

# Error codes: only TH010, TH012, TH017 and TH020, each with its registered
# name as the hint and its registered message.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
raises=$(awk '
  /raise exception using errcode/ { stmt = $0; grab = 1 }
  grab {
    if (stmt != $0) { line = $0; sub(/^ +/, "", line); stmt = stmt " " line }
    if ($0 ~ /;$/) { sub(/^ +/, "", stmt); print stmt; grab = 0 }
  }
' <<<"$code")
raise_re="^raise exception using errcode = '(TH[0-9]{3})', message = '([^']+)', hint = '([a-z_]+)';$"
codes=''
while IFS= read -r line; do
  [[ "$line" =~ $raise_re ]] || fail "unexpected raise form: $line"
  code_id="${BASH_REMATCH[1]}" msg="${BASH_REMATCH[2]}" hint="${BASH_REMATCH[3]}"
  row=$(registry_row "$code_id")
  [[ -n "$row" ]] || fail "$code_id is not in the registry in $contract"
  grep -Fq "| \`$code_id\` | \`$hint\` |" <<<"$row" || fail "$code_id is raised with hint $hint, not the registered name"
  grep -Fq "$msg" <<<"$row" || fail "$code_id message '$msg' is not in its registry row"
  # shellcheck disable=SC2016
  grep -Fq '`delete_enrolment_now`' <<<"$row" || fail "the $code_id registry row must name delete_enrolment_now"
  codes+="$code_id "
done <<<"$raises"
[[ "$codes" == 'TH010 TH017 TH020 TH012 ' ]] ||
  fail "delete_enrolment_now raises TH010, TH017, TH020 and TH012, in that order, and no other TH code (got: $codes)"
[[ "$(grep -c 'raise ' <<<"$code")" -eq 6 ]] ||
  fail 'delete_enrolment_now raises exactly six errors: 42501, TH010, 23514, TH017, TH020, TH012'

# Contract -------------------------------------------------------------------------------
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_enrolment_delete_now.sh`' "$contract" || fail "$contract must name this check"
enrolments_section=$(sed -n '/^## Programmes, enrolments and consents$/,/^## /p' "$contract" | tr '\n' ' ' | sed -E 's/ +/ /g')
# shellcheck disable=SC2016
grep -Fq '`delete_enrolment_now(' <<<"$enrolments_section" ||
  fail 'the enrolments section must describe delete_enrolment_now'
# shellcheck disable=SC2016
grep -Fq '`deletion_barrier_open()`' <<<"$enrolments_section" ||
  fail 'the enrolments section must describe the deletion barrier on enrolment updates'

echo 'Enrolment delete-now static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  run_psql() {
    env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
      psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1
  }
  echo 'SQL test and control against VERIFY_DB_URL (local database):'
  out=$(print_sql | run_psql) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH914A_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH914A_CONTROL_DIRECT_DELETE_REFUSED' ||
    fail 'control: a direct delete of an own enrolment as authenticated was not refused'
  echo 'Enrolment delete-now SQL test and control passed.'
fi
