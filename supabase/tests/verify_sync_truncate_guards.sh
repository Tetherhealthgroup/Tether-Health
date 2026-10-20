#!/usr/bin/env bash
# Checks that sync rows are removed only by row deletes, with their programme
# or account: a statement trigger on every sync_* table refuses TRUNCATE for
# every role, in every session mode, and the deletion paths
# (delete_my_app_data, deleting an enrolment, deleting an account) still
# remove sync rows with DELETE.
#
#   bash supabase/tests/verify_sync_truncate_guards.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the truncate control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test creates and switches to test
#       roles, so the URL's user must be a superuser.
#   bash <this script> --print-sql           print the SQL test
#   bash <this script> --print-control-sql   print the truncate control: it
#       truncates the sync tables as a superuser and reports whether the
#       truncates were refused (migrated database) or completed (a database
#       without the guards)
#
# Both SQL scripts use synthetic identities only, run in one transaction and
# always roll back.
set -euo pipefail

migration="supabase/migrations/202610180007_sync_truncate_guards.sql"
migrations_dir="supabase/migrations"
contract="docs/contracts/database.md"

print_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'FAIL setup: this SQL test needs a superuser connection (it creates and switches to test roles)';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role')
     or not exists (select 1 from pg_catalog.pg_roles where rolname = 'thsync') then
    raise exception 'FAIL setup: role service_role or thsync is missing';
  end if;
end;
$setup$;

create schema th989_test;
select set_config('th989.superuser', current_user, true);

create function th989_test.ok(p_cond boolean, p_label text)
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
create function th989_test.refused(
  p_sql text, p_state text, p_message_like text, p_label text,
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

-- Every TRUNCATE form that reaches a sync table, each refused with p_state:
-- TH019 from the guard, or 42501 for a role without the truncate privilege.
create function th989_test.truncates_refused(p_who text, p_state text)
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
begin
  foreach stmt in array array[
    'truncate public.sync_lapse',
    'truncate only public.sync_lapse',
    'truncate public.sync_lapse cascade',
    'truncate public.sync_answer',
    'truncate public.sync_answer cascade',
    'truncate public.sync_area cascade',
    'truncate public.sync_account cascade',
    'truncate public.sync_account, public.sync_area, public.sync_answer, public.sync_lapse'
  ] loop
    if p_state = 'TH019' then
      perform th989_test.refused(stmt, 'TH019', 'Sync rows are removed only with their enrolment or account',
        p_who || ': ' || stmt || ' is refused', 'sync_rows_delete_only');
    else
      perform th989_test.refused(stmt, p_state, 'permission denied%',
        p_who || ': ' || stmt || ' is refused (no truncate privilege)');
    end if;
  end loop;
end;
$f$;

-- TRUNCATE ... CASCADE of tables that would cascade into the sync tables.
-- programmes reaches sync_area before any other guarded table, so its guard
-- refuses with TH019. enrolments and auth.users may reach a consent table
-- first; either guard's refusal (TH003 or TH019) keeps every row.
create function th989_test.cascades_refused(p_who text)
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
  got_hint text;
begin
  perform th989_test.refused('truncate public.programmes cascade', 'TH019',
    'Sync rows are removed only with their enrolment or account',
    p_who || ': truncate public.programmes cascade is refused', 'sync_rows_delete_only');
  foreach stmt in array array[
    'truncate public.enrolments cascade',
    'truncate auth.users cascade'
  ] loop
    begin
      execute stmt;
    exception when others then
      get stacked diagnostics got_hint = pg_exception_hint;
      if (sqlstate = 'TH003' and got_hint = 'consent_immutable')
         or (sqlstate = 'TH019' and got_hint = 'sync_rows_delete_only') then
        raise notice 'PASS %: % is refused (% %) hint %', p_who, stmt, sqlstate, sqlerrm, got_hint;
        continue;
      end if;
      raise exception 'FAIL %: % (got % % hint %)', p_who, stmt, sqlstate, sqlerrm, got_hint;
    end;
    raise exception 'FAIL %: % (statement succeeded)', p_who, stmt;
  end loop;
end;
$f$;

-- Lets p_role truncate every table a cascade above can reach.
create function th989_test.grant_cascade_truncate(p_role text)
returns void language plpgsql set search_path = '' as $f$
declare
  nsp text;
begin
  foreach nsp in array array['public', 'auth', 'storage'] loop
    execute pg_catalog.format('grant usage on schema %I to %I', nsp, p_role);
    execute pg_catalog.format('grant truncate on all tables in schema %I to %I', nsp, p_role);
  end loop;
end;
$f$;

grant usage on schema th989_test to public;
grant execute on all functions in schema th989_test to public;
revoke all on function th989_test.grant_cascade_truncate(text) from public;

-- Catalogue -------------------------------------------------------------------
-- The sync tables, read from the catalogue.
select th989_test.ok(
  (select string_agg(c.relname, ',' order by c.relname)
   from pg_catalog.pg_class as c
   where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'p')
     and c.relname like 'sync\_%') = 'sync_account,sync_answer,sync_area,sync_lapse',
  'catalogue: the sync tables are sync_account, sync_answer, sync_area and sync_lapse');
select th989_test.ok(
  not exists (
    select 1
    from pg_catalog.pg_class as c
    where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'p')
      and c.relname like 'sync\_%'
      and not exists (
        select 1 from pg_catalog.pg_trigger as t
        join pg_catalog.pg_proc as p on p.oid = t.tgfoid
        where t.tgrelid = c.oid and not t.tgisinternal
          and t.tgtype::integer = 34 and t.tgenabled = 'A'
          and p.oid = 'public.sync_truncate_guard()'::regprocedure)),
  'catalogue: every sync table has a before-truncate statement guard enabled in every session mode');
select th989_test.ok(
  (select string_agg(c.relname || ':' || t.tgname || ':' || t.tgtype || ':' || p.proname
            || ':' || t.tgenabled::text, ',' order by c.relname, t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_class as c on c.oid = t.tgrelid
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where c.relnamespace = 'public'::regnamespace and c.relname like 'sync\_%'
     and not t.tgisinternal and (t.tgtype::integer & 32) <> 0) =
  'sync_account:sync_account_truncate_guard:34:sync_truncate_guard:A,'
  'sync_answer:sync_answer_truncate_guard:34:sync_truncate_guard:A,'
  'sync_area:sync_area_truncate_guard:34:sync_truncate_guard:A,'
  'sync_lapse:sync_lapse_truncate_guard:34:sync_truncate_guard:A',
  'sync tables: exactly one truncate trigger each, before truncate, for each statement, enabled in every session mode');
select th989_test.ok(
  (select not p.prosecdef and p.proconfig = array['search_path=""']
     and pg_catalog.strpos(p.prosrc, 'TH019') > 0
   from pg_catalog.pg_proc as p
   where p.oid = 'public.sync_truncate_guard()'::regprocedure)
  and not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
    where p.oid = 'public.sync_truncate_guard()'::regprocedure
      and (a.grantee = 0 or a.grantee in ('anon'::regrole, 'authenticated'::regrole,
                                          'thsync'::regrole, 'service_role'::regrole))),
  'sync_truncate_guard: raises TH019, security invoker, empty search_path; no execute for anon, authenticated, thsync, service_role or PUBLIC');
select th989_test.ok(
  not exists (
    select 1
    from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(
      coalesce(c.relacl, pg_catalog.acldefault('r', c.relowner))) as a
    where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'p')
      and c.relname like 'sync\_%'
      and a.privilege_type = 'TRUNCATE' and a.grantee <> c.relowner),
  'sync tables: no role other than the owner (and no PUBLIC grant) holds truncate');
select th989_test.ok(
  not exists (
    select 1
    from unnest(array['anon', 'authenticated', 'thsync', 'service_role']) as r(role_name)
    cross join unnest(array['public.sync_account', 'public.sync_area',
                            'public.sync_answer', 'public.sync_lapse']) as s(table_name)
    where has_table_privilege(r.role_name, s.table_name, 'TRUNCATE')),
  'anon, authenticated, thsync and service_role hold no truncate privilege on the sync tables');

-- Synthetic identities and sync rows --------------------------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009890a1', 'synthetic-user-a1@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009890b1', 'synthetic-user-b1@example.test',
   'authenticated', 'authenticated');
insert into public.enrolments (id, user_id, programme_code, status) values
  ('00000000-0000-4000-8000-00000989e0a1', '00000000-0000-4000-8000-0000009890a1', 'hw', 'focus'),
  ('00000000-0000-4000-8000-00000989e0a2', '00000000-0000-4000-8000-0000009890a1', 'st', 'learn_only'),
  ('00000000-0000-4000-8000-00000989e0b1', '00000000-0000-4000-8000-0000009890b1', 'hw', 'focus');
-- The focus-cap check on these enrolments is deferred to commit; run it now,
-- so no trigger event is pending when a truncate cascades to enrolments, and
-- defer it again.
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
insert into public.sync_account (user_id) values
  ('00000000-0000-4000-8000-0000009890a1'),
  ('00000000-0000-4000-8000-0000009890b1');
insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq) values
  ('00000000-0000-4000-8000-0000009890a1', '00000000-0000-4000-8000-00000989e0a1', 'hw', 1, 1),
  ('00000000-0000-4000-8000-0000009890a1', '00000000-0000-4000-8000-00000989e0a2', 'st', 1, 2),
  ('00000000-0000-4000-8000-0000009890b1', '00000000-0000-4000-8000-00000989e0b1', 'hw', 1, 1);
insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
  ('00000000-0000-4000-8000-0000009890a1', 'hw', 'synthetic_screen_1', '{"v": 1}'),
  ('00000000-0000-4000-8000-0000009890a1', 'st', 'synthetic_screen_1', '{"v": 2}'),
  ('00000000-0000-4000-8000-0000009890b1', 'hw', 'synthetic_screen_1', '{"v": 3}');
insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
  ('00000000-0000-4000-8000-0000009890a1', 'hw', 0, '2026-01-01T00:00:00Z'),
  ('00000000-0000-4000-8000-0000009890a1', 'hw', 1, '2026-01-02T00:00:00Z'),
  ('00000000-0000-4000-8000-0000009890a1', 'st', 0, '2026-01-03T00:00:00Z'),
  ('00000000-0000-4000-8000-0000009890b1', 'hw', 0, '2026-01-04T00:00:00Z');

-- A fingerprint of every sync row, to show refused truncates change nothing.
create function th989_test.fingerprint()
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.md5(
    coalesce((select string_agg(pg_catalog.to_jsonb(s)::text, '|' order by s.user_id)
              from public.sync_account as s), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(s)::text, '|' order by s.user_id, s.programme_code)
              from public.sync_area as s), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(s)::text, '|'
                                order by s.user_id, s.programme_code, s.screen_id)
              from public.sync_answer as s), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(s)::text, '|'
                                order by s.user_id, s.programme_code, s.ordinal)
              from public.sync_lapse as s), ''))
$f$;
grant execute on function th989_test.fingerprint() to public;
select set_config('th989.sync', th989_test.fingerprint(), true);

-- A fingerprint of the sync rows and of every other table the cascades above
-- reach, to show a refused cascade changes nothing.
create function th989_test.wide_fingerprint()
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.md5(
    th989_test.fingerprint() || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(t)::text, '|' order by t.code)
              from public.programmes as t), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(t)::text, '|' order by t.id)
              from public.enrolments as t), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(t)::text, '|' order by t.id)
              from public.programme_consents as t), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(t)::text, '|' order by t.id)
              from public.account_consents as t), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(t)::text, '|' order by t.id)
              from public.profiles as t), '') || '#' ||
    (select count(*)::text from public.quit_plans) || '/' ||
    (select count(*)::text from public.program_data) || '/' ||
    (select count(*)::text from public.consent_documents) || '/' ||
    (select count(*)::text from auth.users))
$f$;
select set_config('th989.wide', th989_test.wide_fingerprint(), true);
select th989_test.ok(
  (select count(*) from public.sync_account) = 2
  and (select count(*) from public.sync_area) = 3
  and (select count(*) from public.sync_answer) = 3
  and (select count(*) from public.sync_lapse) = 4,
  'setup: 2 sync accounts, 3 areas, 3 answers and 4 lapses');

-- Superuser (as a migration runs) --------------------------------------------------
select th989_test.truncates_refused('superuser', 'TH019');
-- sync_account and sync_area are referenced by other sync tables: without
-- CASCADE the foreign keys refuse first (0A000).
select th989_test.refused('truncate public.sync_account',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'superuser: truncate sync_account without cascade is refused');
select th989_test.refused('truncate public.sync_area',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'superuser: truncate sync_area without cascade is refused');
select th989_test.cascades_refused('superuser');
select th989_test.ok(th989_test.wide_fingerprint() = current_setting('th989.wide'),
  'superuser: the refused truncates left every sync row and every row the cascades reach untouched');

-- A role that bypasses row-level security --------------------------------------------
create role th989_bypass nologin bypassrls;
grant usage on schema public to th989_bypass;
grant select, truncate on public.sync_account, public.sync_area, public.sync_answer,
  public.sync_lapse to th989_bypass;
select th989_test.grant_cascade_truncate('th989_bypass');
set local role th989_bypass;
select th989_test.ok(
  (select count(*) from public.sync_lapse) = 4,
  'bypass role: sees every lapse (it holds truncate and select)');
select th989_test.truncates_refused('bypass role', 'TH019');
select th989_test.cascades_refused('bypass role');
reset role;
select th989_test.ok(th989_test.wide_fingerprint() = current_setting('th989.wide'),
  'bypass role: the refused truncates left every sync row and every row the cascades reach untouched');

-- A role subject to row-level security, holding the truncate privilege ---------------
create role th989_plain nologin;
grant usage on schema public to th989_plain;
grant select, truncate on public.sync_account, public.sync_area, public.sync_answer,
  public.sync_lapse to th989_plain;
select th989_test.grant_cascade_truncate('th989_plain');
set local role th989_plain;
select th989_test.truncates_refused('non-bypass role', 'TH019');
select th989_test.cascades_refused('non-bypass role');
reset role;
select th989_test.ok(th989_test.wide_fingerprint() = current_setting('th989.wide'),
  'non-bypass role: the refused truncates left every sync row and every row the cascades reach untouched');

-- thsync, if it were granted truncate ------------------------------------------------
grant truncate on public.sync_account, public.sync_area, public.sync_answer,
  public.sync_lapse to thsync;
set session authorization thsync;
select th989_test.ok(session_user = 'thsync', 'thsync: the session user is thsync');
select th989_test.truncates_refused('thsync holding truncate', 'TH019');
-- Back to the superuser that started the test.
do $back$
begin
  execute pg_catalog.format('set session authorization %I', current_setting('th989.superuser'));
end;
$back$;
revoke truncate on public.sync_account, public.sync_area, public.sync_answer,
  public.sync_lapse from thsync;
select th989_test.ok(th989_test.fingerprint() = current_setting('th989.sync'),
  'thsync: the refused truncates left every sync row untouched');

-- The table owner, when it is not a superuser ----------------------------------------
create role th989_owner nologin;
grant usage on schema public to th989_owner;
select set_config('th989.owner',
  (select relowner::regrole::text from pg_catalog.pg_class
   where oid = 'public.sync_lapse'::regclass), true);
alter table public.sync_account owner to th989_owner;
alter table public.sync_area owner to th989_owner;
alter table public.sync_answer owner to th989_owner;
alter table public.sync_lapse owner to th989_owner;
select th989_test.grant_cascade_truncate('th989_owner');
set local role th989_owner;
select th989_test.truncates_refused('table owner', 'TH019');
select th989_test.cascades_refused('table owner');
reset role;
do $restore$
declare
  t text;
begin
  foreach t in array array['sync_account', 'sync_area', 'sync_answer', 'sync_lapse'] loop
    execute pg_catalog.format('alter table public.%I owner to %s', t, current_setting('th989.owner'));
  end loop;
end;
$restore$;
select th989_test.ok(th989_test.wide_fingerprint() = current_setting('th989.wide'),
  'table owner: the refused truncates left every sync row and every row the cascades reach untouched');

-- service_role, authenticated and anon ------------------------------------------------
-- None holds the truncate privilege, so the privilege check refuses first.
set local role service_role;
select th989_test.truncates_refused('service_role', '42501');
reset role;
set local role authenticated;
select th989_test.truncates_refused('authenticated', '42501');
reset role;
set local role anon;
select th989_test.truncates_refused('anon', '42501');
reset role;
select th989_test.ok(th989_test.fingerprint() = current_setting('th989.sync'),
  'every refused truncate left every sync row untouched');

-- The guards fire in every session mode ----------------------------------------------
set local session_replication_role = replica;
select th989_test.truncates_refused('superuser, replica session', 'TH019');
select th989_test.cascades_refused('superuser, replica session');
reset session_replication_role;
select th989_test.ok(th989_test.wide_fingerprint() = current_setting('th989.wide'),
  'replica session: the refused truncates left every sync row and every row the cascades reach untouched');

-- Row deletes still remove sync rows ---------------------------------------------------
-- "Delete now": A deletes one enrolment; its area, answers and lapses go with
-- it (cascade).
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000009890a1', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000009890a1","role":"authenticated"}', true);
set local role authenticated;
delete from public.enrolments where id = '00000000-0000-4000-8000-00000989e0a2';
reset role;
select th989_test.ok(
  (select count(*) from public.sync_area where enrolment_id = '00000000-0000-4000-8000-00000989e0a2') = 0
  and (select count(*) from public.sync_answer
       where user_id = '00000000-0000-4000-8000-0000009890a1' and programme_code = 'st') = 0
  and (select count(*) from public.sync_lapse
       where user_id = '00000000-0000-4000-8000-0000009890a1' and programme_code = 'st') = 0
  and (select count(*) from public.sync_lapse) = 3,
  'A: deleting an enrolment still removes its sync area, answers and lapses (row delete cascade)');

-- delete_my_app_data, end to end.
-- A recent sign-in, which begin_account_deletion requires.
select set_config('request.jwt.claims', (current_setting('request.jwt.claims')::jsonb
  || jsonb_build_object('amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30))))::text, true);
set local role authenticated;
select th989_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
-- Owner context, as delete_my_account runs it: the superuser with A's claims.
reset role;
select set_config('th989.a_receipt', public.delete_my_app_data('DELETE')::text, true);
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '', true);
select th989_test.ok(
  (current_setting('th989.a_receipt')::jsonb ->> 'sync_accounts')::integer = 1
  and (current_setting('th989.a_receipt')::jsonb ->> 'sync_areas')::integer = 1
  and (current_setting('th989.a_receipt')::jsonb ->> 'sync_answers')::integer = 1
  and (current_setting('th989.a_receipt')::jsonb ->> 'sync_lapses')::integer = 2,
  'A: delete_my_app_data deletes A''s sync rows and returns their counts');
select th989_test.ok(
  (select count(*) from public.sync_account where user_id = '00000000-0000-4000-8000-0000009890a1') = 0
  and (select count(*) from public.sync_area where user_id = '00000000-0000-4000-8000-0000009890a1') = 0
  and (select count(*) from public.sync_answer where user_id = '00000000-0000-4000-8000-0000009890a1') = 0
  and (select count(*) from public.sync_lapse where user_id = '00000000-0000-4000-8000-0000009890a1') = 0,
  'A: no sync account, area, answer or lapse of A is left');
select th989_test.ok(
  (select count(*) from public.sync_account where user_id = '00000000-0000-4000-8000-0000009890b1') = 1
  and (select count(*) from public.sync_area where user_id = '00000000-0000-4000-8000-0000009890b1') = 1
  and (select count(*) from public.sync_answer where user_id = '00000000-0000-4000-8000-0000009890b1') = 1
  and (select count(*) from public.sync_lapse where user_id = '00000000-0000-4000-8000-0000009890b1') = 1,
  'B: deleting A left B''s sync rows untouched');

-- Deleting B's account (as the auth service does) cascades through sync_account.
delete from auth.users where id = '00000000-0000-4000-8000-0000009890b1';
select th989_test.ok(
  (select count(*) from public.sync_account) = 0
  and (select count(*) from public.sync_area) = 0
  and (select count(*) from public.sync_answer) = 0
  and (select count(*) from public.sync_lapse) = 0,
  'B: deleting the account removes every sync row of B (row delete cascade); no sync row is left');

select 'TH989_SQL_TESTS_COMPLETE' as result;
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

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009890c1', 'synthetic-user-c1@example.test',
   'authenticated', 'authenticated');
insert into public.enrolments (id, user_id, programme_code, status) values
  ('00000000-0000-4000-8000-00000989e0c1', '00000000-0000-4000-8000-0000009890c1', 'hw', 'focus');
insert into public.sync_account (user_id) values ('00000000-0000-4000-8000-0000009890c1');
insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq) values
  ('00000000-0000-4000-8000-0000009890c1', '00000000-0000-4000-8000-00000989e0c1', 'hw', 1, 1);
insert into public.sync_answer (user_id, programme_code, screen_id, payload) values
  ('00000000-0000-4000-8000-0000009890c1', 'hw', 'synthetic_screen_1', '{"v": 1}');
insert into public.sync_lapse (user_id, programme_code, ordinal, at) values
  ('00000000-0000-4000-8000-0000009890c1', 'hw', 0, '2026-01-01T00:00:00Z');

-- Each truncate runs in its own block; the outcome is "completed" or the
-- SQLSTATE that refused it.
do $control$
declare
  stmt text;
  outcome text;
  outcomes text := '';
begin
  foreach stmt in array array[
    'truncate public.sync_lapse',
    'truncate public.sync_answer',
    'truncate public.sync_account cascade'
  ] loop
    begin
      execute stmt;
      outcome := 'completed';
    exception when others then
      outcome := sqlstate;
    end;
    raise notice 'CONTROL %: %', stmt, outcome;
    outcomes := outcomes || outcome || ',';
  end loop;
  perform pg_catalog.set_config('th989c.outcomes', outcomes, true);
  perform pg_catalog.set_config('th989c.rows',
    ((select count(*) from public.sync_account) + (select count(*) from public.sync_area)
     + (select count(*) from public.sync_answer) + (select count(*) from public.sync_lapse))::text,
    true);
  raise notice 'CONTROL sync rows left: %', pg_catalog.current_setting('th989c.rows');
end;
$control$;

select case
  when current_setting('th989c.outcomes') = 'completed,completed,completed,'
   and current_setting('th989c.rows') = '0'
    then 'TH989_CONTROL_TRUNCATE_COMPLETED'
  when current_setting('th989c.outcomes') = 'TH019,TH019,TH019,'
   and current_setting('th989c.rows')::integer > 0
    then 'TH989_CONTROL_TRUNCATE_REFUSED'
  else 'TH989_CONTROL_UNEXPECTED'
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
  echo "Sync truncate guard check failed: $1" >&2
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

[[ -f "$migration" ]] || fail "missing $migration"
[[ -f "$contract" ]] || fail "missing $contract"
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

# The migration name follows the convention (12-digit version, lowercase name).
[[ "${migration##*/}" =~ ^[0-9]{12}_[a-z0-9_]+\.sql$ ]] ||
  fail "${migration##*/} is not YYYYMMDDNNNN_name.sql"

migration_files=()
while IFS= read -r -d '' path; do
  migration_files+=("$path")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -name '*.sql' -print0 | LC_ALL=C sort -z)

sql=$(sed 's/--.*$//' "$migration")
all_sql=$(sed 's/--.*$//' "${migration_files[@]}")

# Every sync table any migration creates has a before-truncate statement guard
# on sync_truncate_guard that is enabled always.
sync_tables=$(grep -Eo '^create table public\.sync_[a-z_]+' <<<"$all_sql" | sed 's/^create table public\.//' | LC_ALL=C sort -u)
[[ "$(tr '\n' ' ' <<<"$sync_tables")" == 'sync_account sync_answer sync_area sync_lapse ' ]] ||
  fail "the migrations create these sync tables: $(tr '\n' ' ' <<<"$sync_tables")(add a truncate guard for each new one, then update this list)"
while read -r table; do
  guard_fn=public.sync_truncate_guard
  grep -A2 "^create trigger ${table}_truncate_guard\$" <<<"$all_sql" | tr '\n' ' ' |
    grep -Fq "before truncate on public.$table for each statement execute function $guard_fn();" ||
    fail "${table} must have ${table}_truncate_guard running $guard_fn before truncate, for each statement"
  grep -A1 -Fx "alter table public.$table" <<<"$all_sql" |
    grep -Fxq "enable always trigger ${table}_truncate_guard;" ||
    fail "${table}_truncate_guard must be enabled always"
done <<<"$sync_tables"
[[ "$(grep -Ec '^create trigger ' <<<"$sql")" -eq 4 ]] ||
  fail 'this migration creates exactly the four truncate triggers'

# The guard refuses unconditionally, with TH019 and its registered hint.
body=$(sed -n '/^create function public\.sync_truncate_guard()$/,/^\$\$;$/p' <<<"$sql")
[[ -n "$body" ]] || fail 'missing public.sync_truncate_guard()'
grep -Fxq 'security invoker' <<<"$body" || fail 'sync_truncate_guard must be security invoker'
grep -Fxq "set search_path = ''" <<<"$body" || fail "sync_truncate_guard must set search_path = ''"
[[ "$(sed -n '/^begin$/,/^end;$/p' <<<"$body" | tr -s ' \n' ' ')" == \
  "begin raise exception using errcode = 'TH019', message = 'Sync rows are removed only with their enrolment or account', hint = 'sync_rows_delete_only'; end; " ]] ||
  fail 'sync_truncate_guard must only raise TH019 (Sync rows are removed only with their enrolment or account, sync_rows_delete_only), whatever the role'

# Privileges and hygiene.
grep -A1 -Fx 'revoke all on function public.sync_truncate_guard()' <<<"$sql" |
  grep -Fxq 'from public, anon, authenticated;' ||
  fail 'sync_truncate_guard: revoke from public, anon and authenticated'
grep -A1 -Fx 'revoke truncate on public.sync_account, public.sync_area, public.sync_answer, public.sync_lapse' <<<"$sql" |
  grep -Fxq 'from public, anon, authenticated, thsync;' ||
  fail 'PUBLIC, anon, authenticated and thsync: revoke truncate on the sync tables'
[[ "$(grep -Ec '^create (or replace )?function ' <<<"$sql")" -eq 1 ]] ||
  fail 'this migration creates one function'
if grep -Eq '^security definer$' <<<"$sql"; then
  fail 'no function in this migration may be security definer'
fi
if grep -Eiq '(^|[^a-z_])grant ' <<<"$sql"; then
  fail 'this migration grants nothing'
fi
if grep -Eiq '^revoke ' <<<"$sql" && grep -Ei '^revoke ' <<<"$sql" | grep -Eqv '^revoke (all on function public\.sync_truncate_guard\(\)|truncate on public\.sync_account, public\.sync_area, public\.sync_answer, public\.sync_lapse)$'; then
  fail 'this migration revokes only execute on its guards and truncate on the sync tables'
fi
if grep -Eiq 'service_role' <<<"$sql"; then
  fail 'this migration does not change service_role privileges'
fi
if grep -Eiq '^(create|drop|alter) policy ' <<<"$sql"; then
  fail 'this migration does not change policies'
fi
if grep -Eiq 'disable row level security|no force row level security|(^|[^a-z_])bypassrls|(create|alter|drop) role|owner to|disable trigger' <<<"$sql"; then
  fail 'migration must not weaken RLS, change roles or disable triggers'
fi
if grep -Eiq 'secret|password[[:space:]]*=' <<<"$sql"; then
  fail 'migration must not contain credentials'
fi

# Scans each migration for statements that would let a sync truncate run or
# weaken a sync truncate guard. Prints the first problem in the SQL on stdin,
# or nothing:
#   * a truncate statement, or a dynamic execute whose text has "truncate";
#   * setting session_replication_role;
#   * create or replace, alter or drop of the function sync_truncate_guard
#     (with or without the public. schema);
#   * drop trigger or alter trigger (rename) of a sync guard;
#   * disable or enable of a sync guard by name, except enable always;
#   * disable or enable of trigger all or trigger user on a sync table.
# Comments and double quotes are removed and the text is joined into one
# lower-case line, so a statement split over lines is matched as one. Trigger
# events ("truncate on") and "execute function" in create trigger are not
# statements and are set aside.
guards='sync_account_truncate_guard|sync_area_truncate_guard|sync_answer_truncate_guard|sync_lapse_truncate_guard'
migration_problem() {
  local text change stmt
  text=$(sed 's/--.*$//' | tr '\n\t' '  ' | tr -d '"' | tr '[:upper:]' '[:lower:]' |
    sed -E 's/ +/ /g; s/(^|[^a-z_])truncate on /\1trigger_event_on /g; s/(^|[^a-z_])execute (function|procedure) /\1runs_\2 /g')
  if grep -Eq "(^|[^a-z_])execute[^;]*[^a-z_]truncate([^a-z_]|\$)" <<<"$text"; then
    echo 'dynamic execute of a truncate'; return
  fi
  if grep -Eq "(^|[^a-z_'])truncate( table)? (only )?[a-z_.]" <<<"$text"; then
    echo 'truncate statement'; return
  fi
  if grep -Fq 'session_replication_role' <<<"$text"; then
    echo 'sets session_replication_role'; return
  fi
  if grep -Eq "create or replace function (public\.)?sync_truncate_guard([^a-z_]|\$)" <<<"$text"; then
    echo 'redefines sync_truncate_guard'; return
  fi
  if grep -Eq "(alter|drop) function (if exists )?(public\.)?sync_truncate_guard([^a-z_]|\$)" <<<"$text"; then
    echo 'alters or drops sync_truncate_guard'; return
  fi
  if grep -Eq "drop trigger (if exists )?($guards)([^a-z_]|\$)" <<<"$text"; then
    echo 'drops a sync truncate guard'; return
  fi
  if grep -Eq "alter trigger (if exists )?($guards)([^a-z_]|\$)" <<<"$text"; then
    echo 'alters or renames a sync truncate guard'; return
  fi
  while read -r change; do
    [[ -n "$change" ]] || continue
    if [[ "$change" =~ ($guards)$ ]]; then
      [[ "$change" =~ ^enable\ always\ trigger\ ($guards)$ ]] || {
        echo "changes when a sync truncate guard fires ($change)"; return
      }
    fi
  done < <(grep -Eo '(disable|enable)( always| replica)? trigger [a-z_]+' <<<"$text" || true)
  while read -r stmt; do
    if [[ "$stmt" =~ ^alter\ table\ (if\ exists\ )?(only\ )?(public\.)?(sync_[a-z_]+)[\ ,].*((disable|enable)(\ always|\ replica)?\ trigger\ (all|user))([^a-z_]|$) ]]; then
      echo "changes when the sync truncate guards fire (${BASH_REMATCH[5]} on ${BASH_REMATCH[4]})"; return
    fi
  done < <(tr ';' '\n' <<<"$text" | sed -E 's/^ +//')
}

# Self-test of the scan; runs every time.
check_scan() {
  local want="$1" got
  shift
  got=$(printf '%s\n' "$@" | migration_problem)
  [[ "$got" == "$want" ]] || fail "migration scan self-test: expected '$want', got '$got' for: $*"
}
check_scan 'truncate statement' 'begin;' 'TRUNCATE' '  public.sync_lapse;' 'commit;'
check_scan 'truncate statement' 'truncate table only public.sync_account cascade;'
check_scan 'truncate statement' 'truncate "public"."sync_lapse";'
check_scan 'dynamic execute of a truncate' "execute format('truncate %I', t);"
check_scan 'dynamic execute of a truncate' 'perform 1;' "EXECUTE 'TRUNCATE ' ||" "  'public.sync_answer';"
check_scan 'sets session_replication_role' 'set local session_replication_role = replica;'
check_scan 'redefines sync_truncate_guard' 'create or replace function public.sync_truncate_guard()'
check_scan 'redefines sync_truncate_guard' 'create or replace function "public"."sync_truncate_guard"()'
check_scan 'redefines sync_truncate_guard' 'CREATE OR REPLACE FUNCTION sync_truncate_guard()'
check_scan 'redefines sync_truncate_guard' 'create or replace function "sync_truncate_guard" ()'
check_scan 'alters or drops sync_truncate_guard' 'drop function public.sync_truncate_guard();'
check_scan 'alters or drops sync_truncate_guard' 'drop function if exists "sync_truncate_guard";'
check_scan 'alters or drops sync_truncate_guard' 'alter function sync_truncate_guard() security definer;'
check_scan 'drops a sync truncate guard' 'drop trigger if exists sync_lapse_truncate_guard' '  on public.sync_lapse;'
check_scan 'drops a sync truncate guard' 'drop trigger "sync_area_truncate_guard" on "public"."sync_area";'
check_scan 'alters or renames a sync truncate guard' \
  'alter trigger sync_answer_truncate_guard on public.sync_answer' '  rename to old_guard;'
check_scan 'alters or renames a sync truncate guard' \
  'ALTER TRIGGER "sync_lapse_truncate_guard" ON "public"."sync_lapse" RENAME TO x;'
check_scan 'changes when a sync truncate guard fires (disable trigger sync_area_truncate_guard)' \
  'alter table public.sync_area disable trigger sync_area_truncate_guard;'
check_scan 'changes when a sync truncate guard fires (enable trigger sync_lapse_truncate_guard)' \
  'alter table public.sync_lapse' 'enable trigger sync_lapse_truncate_guard;'
check_scan 'changes when a sync truncate guard fires (enable replica trigger sync_account_truncate_guard)' \
  'alter table public.sync_account enable replica trigger "sync_account_truncate_guard";'
check_scan 'changes when the sync truncate guards fire (disable trigger all on sync_lapse)' \
  'alter table public.sync_lapse disable trigger all;'
check_scan 'changes when the sync truncate guards fire (disable trigger user on sync_answer)' \
  'alter table only "public"."sync_answer"' '  DISABLE TRIGGER USER;'
check_scan 'changes when the sync truncate guards fire (enable trigger all on sync_area)' \
  'alter table if exists sync_area enable trigger all;'
check_scan '' 'alter table public.sync_lapse' 'enable always trigger sync_lapse_truncate_guard;' \
  'alter table public.consent_documents enable always trigger consent_documents_guard_truncate;' \
  'alter table public.enrolments disable trigger user;' \
  'alter table public.sync_area disable trigger sync_area_set_updated_at;' \
  'create trigger t before insert or truncate on public.t' \
  'for each statement execute function public.sync_truncate_guard();' \
  'create or replace function public.sync_truncate_guard_note() returns int language sql as $$ select 1 $$;' \
  "  if tg_op = 'TRUNCATE' then" "execute 'select 1';"

for f in "${migration_files[@]}"; do
  problem=$(migration_problem <"$f")
  [[ -z "$problem" ]] || fail "$f: $problem; sync rows are removed with DELETE and the truncate guards stay in place"
done

# The latest delete_my_app_data removes sync rows with DELETE.
latest=$(grep -El '^create (or replace )?function public\.delete_my_app_data\(' "${migration_files[@]}" | tail -n 1)
[[ -n "$latest" ]] || fail 'no definition of public.delete_my_app_data'
delete_body=$(sed -n '/^create \(or replace \)\{0,1\}function public\.delete_my_app_data(/,/^\$\$;/p' "$latest")
for table in sync_lapse sync_answer sync_area sync_account; do
  grep -Fxq "  delete from public.$table where user_id = caller_id;" <<<"$delete_body" ||
    fail "delete_my_app_data must delete $table rows with DELETE"
done
if grep -Eiq '(^|[^a-z_])truncate([^a-z_]|$)' <<<"$delete_body"; then
  fail 'delete_my_app_data must not truncate'
fi

# Registry: TH019 is registered for sync_truncate_guard with its message.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
row=$(grep -E '^\| `TH019` \| `sync_rows_delete_only` \|' "$contract" || true)
[[ -n "$row" ]] || fail 'TH019 sync_rows_delete_only is not in the registry'
# shellcheck disable=SC2016
grep -Fq '`sync_truncate_guard`' <<<"$row" || fail 'the TH019 registry row must name sync_truncate_guard'
grep -Fq '| Sync rows are removed only with their enrolment or account |' <<<"$row" || fail 'the TH019 registry row must carry its message'

# The contract names this migration and the rule it adds.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq 'A trigger refuses `TRUNCATE` on every sync table for every role' "$contract" ||
  fail "$contract must state that a trigger refuses TRUNCATE on every sync table for every role"
# shellcheck disable=SC2016
grep -Fq 'Sync rows are removed only by `DELETE`, together with their programme or account' "$contract" ||
  fail "$contract must state that sync rows are removed only by DELETE with their programme or account"

echo 'Sync truncate guard static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  run_psql() {
    env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
      psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1
  }
  out=$(print_sql | run_psql) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH989_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'truncate control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH989_CONTROL_TRUNCATE_REFUSED' ||
    fail 'truncate control: a truncate of a sync table was not refused'
  echo 'Sync truncate guard SQL test and truncate control passed.'
fi
