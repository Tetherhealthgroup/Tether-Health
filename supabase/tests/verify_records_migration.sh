#!/usr/bin/env bash
# Checks the health records core (202610180015_records.sql): the six tables,
# their row-level security, grants and policies, the routing rule (an
# accepted item, a category the programme receives, the enrolment's live
# records_import consent), the truncate guard (TH028),
# public.delete_record_source_items (refusing in a fixed order, TH029 for
# another member's source) and the extended deletion functions.
#
#   bash supabase/tests/verify_records_migration.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator and changes the owner of
#       delete_record_source_items inside its transaction, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: as
#       authenticated, a synthetic member routes an accepted blood-pressure
#       item to its ScrollFree enrolment (a programme that receives no
#       records) with a live records_import consent, and it reports:
#         TH915A_CONTROL_ROUTE_REFUSED     (expected with the migration:
#             42501 and no route)
#         TH915A_CONTROL_RECORDS_ABSENT    (a tree without the migration:
#             the tables do not exist)
#         TH915A_CONTROL_UNEXPECTED        (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180015_records.sql"
previous="supabase/migrations/202610180013_programme_records.sql"
owner_check_source="supabase/migrations/202610180008_delete_my_account.sql"
contract="docs/contracts/database.md"
config="supabase/config.toml"

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
  if pg_catalog.to_regclass('public.record_items') is null then
    raise exception 'FAIL setup: public.record_items is missing (the records migration is not applied)';
  end if;
end;
$setup$;

select set_config('th915a.superuser', session_user, true);

create schema th915a_test;

create function th915a_test.ok(p_cond boolean, p_label text)
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
create function th915a_test.refused(
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

create function th915a_test.v(p_name text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.current_setting('th915a.' || p_name)
$f$;

create function th915a_test.claims(p_sub text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'sub', p_sub, 'role', 'authenticated', 'aud', 'authenticated',
    'amr', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - 30)))::text
$f$;

-- Switches the session to p_login acting as p_role with p_claims, or back to
-- the superuser that started the test (no SET clause on purpose).
create function th915a_test.act_as(p_login text, p_claims text, p_role text default 'authenticated')
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th915a.superuser') then
    execute pg_catalog.format('set local role %I', p_role);
  end if;
end;
$f$;

-- The record rows of p_user, keyed like the deletion receipt.
create function th915a_test.counts(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'record_routes', (select count(*) from public.record_routes where user_id = p_user),
    'record_items', (select count(*) from public.record_items where user_id = p_user),
    'record_imports', (select count(*) from public.record_imports where user_id = p_user),
    'record_sources', (select count(*) from public.record_sources where user_id = p_user))
$f$;

grant usage on schema th915a_test to public;
grant execute on all functions in schema th915a_test to public;

-- Catalogue ------------------------------------------------------------------------------
select th915a_test.ok(
  (select string_agg(c.relname || ':' || c.relrowsecurity || ':' || c.relforcerowsecurity, ',' order by c.relname collate "C")
   from pg_catalog.pg_class as c
   where c.relnamespace = 'public'::regnamespace and c.relname like 'record\_%' and c.relkind = 'r') =
  'record_categories:true:true,record_category_codes:true:true,record_imports:true:true,'
  'record_items:true:true,record_routes:true:true,record_sources:true:true',
  'catalogue: the six record tables exist with row-level security enabled and forced');
select th915a_test.ok(
  (select string_agg(category, ',' order by category collate "C") from public.record_categories) =
  (select string_agg(d.category, ',' order by d.category collate "C")
   from (select distinct r.category
         from public.programmes as p cross join lateral pg_catalog.unnest(p.receives_resources) as r(category)) as d)
  and (select count(*) from public.record_category_codes) = 0,
  'catalogue: record_categories is exactly the distinct receives_resources values; record_category_codes is empty');
select th915a_test.ok(
  not exists (
    select 1 from pg_catalog.pg_class as c
    cross join pg_catalog.unnest(array['anon', 'service_role', 'thsync']) as r(n)
    where c.relnamespace = 'public'::regnamespace and c.relname like 'record\_%' and c.relkind = 'r'
      and (pg_catalog.has_table_privilege(r.n, c.oid, 'SELECT')
           or pg_catalog.has_any_column_privilege(r.n, c.oid, 'INSERT')
           or pg_catalog.has_any_column_privilege(r.n, c.oid, 'UPDATE')
           or pg_catalog.has_table_privilege(r.n, c.oid, 'DELETE')
           or pg_catalog.has_table_privilege(r.n, c.oid, 'TRUNCATE'))),
  'grants: anon, service_role and thsync hold no privilege on any record table');
select th915a_test.ok(
  (select string_agg(c.relname || '.' || pr.p, ',' order by c.relname collate "C", pr.p collate "C")
   from pg_catalog.pg_class as c
   cross join pg_catalog.unnest(array['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE']) as pr(p)
   where c.relnamespace = 'public'::regnamespace and c.relname like 'record\_%' and c.relkind = 'r'
     and case pr.p
           when 'INSERT' then pg_catalog.has_any_column_privilege('authenticated', c.oid, 'INSERT')
           when 'UPDATE' then pg_catalog.has_any_column_privilege('authenticated', c.oid, 'UPDATE')
           else pg_catalog.has_table_privilege('authenticated', c.oid, pr.p) end) =
  'record_categories.SELECT,record_category_codes.SELECT,record_imports.INSERT,record_imports.SELECT,'
  'record_imports.UPDATE,record_items.INSERT,record_items.SELECT,record_items.UPDATE,'
  'record_routes.INSERT,record_routes.SELECT,record_sources.INSERT,record_sources.SELECT,record_sources.UPDATE',
  'grants: authenticated has exactly the reviewed table privileges (no DELETE, no TRUNCATE)');
select th915a_test.ok(
  (select string_agg(a.attrelid::regclass::text || '.' || a.attname, ',' order by a.attrelid::regclass::text collate "C", a.attname collate "C")
   from pg_catalog.pg_attribute as a
   where a.attrelid in ('public.record_sources'::regclass, 'public.record_imports'::regclass, 'public.record_items'::regclass)
     and a.attnum > 0 and not a.attisdropped
     and pg_catalog.has_column_privilege('authenticated', a.attrelid, a.attname, 'UPDATE')) =
  'record_imports.counts,record_imports.finished_at,record_imports.status,record_items.status,'
  'record_sources.display_name,record_sources.last_synced_at,record_sources.status',
  'grants: authenticated may update only the reviewed columns');
select th915a_test.ok(
  (select string_agg(tablename || ':' || policyname || ':' || cmd, ',' order by tablename collate "C", policyname collate "C")
   from pg_catalog.pg_policies where schemaname = 'public' and tablename like 'record\_%') =
  'record_categories:record_categories_select_authenticated:SELECT,'
  'record_category_codes:record_category_codes_select_authenticated:SELECT,'
  'record_imports:record_imports_insert_own:INSERT,record_imports:record_imports_select_own:SELECT,'
  'record_imports:record_imports_update_own:UPDATE,'
  'record_items:record_items_insert_own:INSERT,record_items:record_items_select_own:SELECT,'
  'record_items:record_items_update_own:UPDATE,'
  'record_routes:record_routes_insert_own:INSERT,record_routes:record_routes_select_own:SELECT,'
  'record_sources:record_sources_insert_own:INSERT,record_sources:record_sources_select_own:SELECT,'
  'record_sources:record_sources_update_own:UPDATE',
  'policies: exactly the reviewed per-command policies, all to authenticated');
select th915a_test.ok(
  (select bool_and(roles = '{authenticated}') from pg_catalog.pg_policies
   where schemaname = 'public' and tablename like 'record\_%')
  and (select bool_and(with_check like '%deletion_barrier_open()%' and with_check like '%(NOT sync_writer_session()))')
       from pg_catalog.pg_policies where schemaname = 'public' and tablename like 'record\_%' and cmd = 'INSERT')
  and (select bool_and(with_check not like '%deletion_barrier_open()%'
                       and qual like '%(NOT sync_writer_session()))'
                       and with_check like '%(NOT sync_writer_session()))')
       from pg_catalog.pg_policies where schemaname = 'public' and tablename like 'record\_%' and cmd = 'UPDATE'),
  'policies: inserts check the deletion barrier, updates do not; every write ends with the sync guard');
select th915a_test.ok(
  (select string_agg(t.tgrelid::regclass::text || ':' || t.tgname || ':' || t.tgenabled::text, ','
     order by t.tgrelid::regclass::text collate "C")
   from pg_catalog.pg_trigger as t
   where not t.tgisinternal and t.tgname like 'record\_%truncate_guard') =
  'record_imports:record_imports_truncate_guard:A,record_items:record_items_truncate_guard:A,'
  'record_routes:record_routes_truncate_guard:A,record_sources:record_sources_truncate_guard:A',
  'truncate guards: one on each member table, enabled always');
select th915a_test.ok(
  not exists (
    select 1 from pg_catalog.pg_constraint as c
    where c.contype = 'f'
      and c.conrelid::regclass::text like 'record\_%'
      and (c.confdeltype in ('n', 'd')
           or c.confrelid::regclass::text ~ '(consent|sync_|care_|caregiver|supporters)')),
  'foreign keys: none to consent, sync or care tables; none sets null or a default');
select th915a_test.ok(
  (select p.prosecdef and p.proconfig = array['search_path=""']
     and pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
     and not pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
     and not pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE')
   from pg_catalog.pg_proc as p where p.oid = 'public.delete_record_source_items(uuid,text)'::regprocedure)
  and not pg_catalog.has_function_privilege('authenticated', 'public.record_rows_truncate_guard()', 'EXECUTE'),
  'functions: delete_record_source_items is definer with an empty search_path, executable by authenticated only');

-- Synthetic members ------------------------------------------------------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000915a0a1', 'synthetic-915a-a@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-00000915a0b1', 'synthetic-915a-b@example.test', 'authenticated', 'authenticated');
insert into public.profiles (id)
select u.id from auth.users as u
where u.id in ('00000000-0000-4000-8000-00000915a0a1', '00000000-0000-4000-8000-00000915a0b1')
  and not exists (select 1 from public.profiles as p where p.id = u.id);
insert into public.enrolments (id, user_id, programme_code, status, mode) values
  ('00000000-0000-4000-8000-00000915ae01', '00000000-0000-4000-8000-00000915a0a1', 'hw', 'focus', null),
  ('00000000-0000-4000-8000-00000915ae02', '00000000-0000-4000-8000-00000915a0a1', 'sf', 'learn_only', 'quit'),
  ('00000000-0000-4000-8000-00000915ae03', '00000000-0000-4000-8000-00000915a0a1', 'st', 'learn_only', null),
  ('00000000-0000-4000-8000-00000915ae11', '00000000-0000-4000-8000-00000915a0b1', 'hw', 'focus', null);
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
select e.id, p.purpose, 'v1-draft', 'en'
from public.enrolments as e
cross join pg_catalog.unnest(array['core', 'records_import']) as p(purpose)
where e.id in ('00000000-0000-4000-8000-00000915ae01', '00000000-0000-4000-8000-00000915ae02',
               '00000000-0000-4000-8000-00000915ae11')
union all
select '00000000-0000-4000-8000-00000915ae03', 'core', 'v1-draft', 'en';

-- A writes its own records ---------------------------------------------------------------
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
-- Members cannot choose ids (no insert grant on id); the superuser gives the
-- new rows fixed synthetic ids before any child row refers to them.
insert into public.record_sources (user_id, kind, fhir_base_url, display_name, status) values
  (auth.uid(), 'smart', 'https://launch.smarthealthit.example/r4', 'Synthetic sandbox', 'connected'),
  (auth.uid(), 'manual', null, 'Entered by you', 'connected');
select th915a_test.act_as(current_setting('th915a.superuser'), null);
update public.record_sources set id = case kind
    when 'smart' then '00000000-0000-4000-8000-00000915a501'::uuid
    else '00000000-0000-4000-8000-00000915a502'::uuid end
where user_id = '00000000-0000-4000-8000-00000915a0a1';
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
insert into public.record_imports (user_id, source_id, status) values
  (auth.uid(), '00000000-0000-4000-8000-00000915a501', 'running');
select th915a_test.act_as(current_setting('th915a.superuser'), null);
update public.record_imports set id = '00000000-0000-4000-8000-00000915a601'
where user_id = '00000000-0000-4000-8000-00000915a0a1';
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
insert into public.record_items (user_id, source_id, import_id, resource_type, category, code_system, code,
  display, value_num, unit_ucum, effective_at, dedupe_key) values
  (auth.uid(), '00000000-0000-4000-8000-00000915a501',
   '00000000-0000-4000-8000-00000915a601', 'Observation', 'blood_pressure', 'http://loinc.org', '8480-6',
   'Systolic blood pressure', 128, 'mm[Hg]', now() - interval '1 day', 'synthetic-key-1'),
  (auth.uid(), '00000000-0000-4000-8000-00000915a501',
   '00000000-0000-4000-8000-00000915a601', 'Observation', 'a1c', 'http://loinc.org', '4548-4',
   'Hemoglobin A1c', 7.4, '%', now() - interval '2 days', 'synthetic-key-2'),
  (auth.uid(), '00000000-0000-4000-8000-00000915a502',
   null, 'Observation', 'a1c', 'http://loinc.org', '4548-4',
   'Hemoglobin A1c', 7.1, '%', now() - interval '3 days', 'synthetic-key-3');
select th915a_test.act_as(current_setting('th915a.superuser'), null);
update public.record_items set id = ('00000000-0000-4000-8000-00000915a70' || pg_catalog.right(dedupe_key, 1))::uuid
where user_id = '00000000-0000-4000-8000-00000915a0a1';
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.ok(
  th915a_test.counts(auth.uid()) = '{"record_routes": 0, "record_items": 3, "record_imports": 1, "record_sources": 2}'::jsonb,
  'A: inserts its own sources, import and items (pending review)');
select th915a_test.refused(
  'insert into public.record_sources (user_id, kind, display_name, status) values (''00000000-0000-4000-8000-00000915a0b1'', ''manual'', ''x'', ''connected'')',
  '42501', '%row-level security%', 'A: cannot insert a source for B');
select th915a_test.refused(
  'insert into public.record_sources (user_id, kind, display_name, status) values (auth.uid(), ''manual'', ''Second'', ''connected'')',
  '23505', '%record_sources_single_kind_key%', 'A: at most one manual source');
select th915a_test.refused(
  'insert into public.record_sources (user_id, kind, display_name, status) values (auth.uid(), ''epic'', ''No URL'', ''connected'')',
  '23514', '%record_sources_fhir_base_url_kind_check%', 'A: a FHIR source needs its base URL');
select th915a_test.refused(
  'insert into public.record_sources (user_id, kind, fhir_base_url, display_name, status) values (auth.uid(), ''epic'', ''http://insecure.example'', ''x'', ''connected'')',
  '23514', '%record_sources_fhir_base_url_check%', 'A: a FHIR base URL must be https');
select th915a_test.refused(
  'insert into public.record_items (user_id, source_id, resource_type, code_system, code, display, dedupe_key) values (auth.uid(), ''00000000-0000-4000-8000-00000915a501'', ''Observation'', ''http://loinc.org'', ''8480-6'', ''x'', ''synthetic-key-1'')',
  '23505', '%record_items_dedupe_key%', 'A: a duplicate (same dedupe key) is refused');
select th915a_test.refused(
  'insert into public.record_items (user_id, source_id, resource_type, category, code_system, code, display, dedupe_key) values (auth.uid(), ''00000000-0000-4000-8000-00000915a501'', ''Observation'', ''unknown_category'', ''http://loinc.org'', ''1-1'', ''x'', ''synthetic-key-9'')',
  '23503', '%record_items_category_fkey%', 'A: an item category must be a known category');
select th915a_test.refused(
  'update public.record_items set value_num = 1 where id = ''00000000-0000-4000-8000-00000915a701''',
  '42501', 'permission denied%', 'A: cannot change an item value (status only)');
select th915a_test.refused(
  'delete from public.record_items where id = ''00000000-0000-4000-8000-00000915a701''',
  '42501', 'permission denied%', 'A: cannot delete an item directly');
select th915a_test.refused(
  'delete from public.record_sources where id = ''00000000-0000-4000-8000-00000915a501''',
  '42501', 'permission denied%', 'A: cannot delete a source directly');

-- Routing --------------------------------------------------------------------------------
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a701'', auth.uid(), ''00000000-0000-4000-8000-00000915ae01'', ''hw'')',
  '42501', '%row-level security%', 'routing: an item pending review is not routed');
update public.record_items set status = 'accepted'
where id in ('00000000-0000-4000-8000-00000915a701', '00000000-0000-4000-8000-00000915a702');
insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values
  ('00000000-0000-4000-8000-00000915a701', auth.uid(), '00000000-0000-4000-8000-00000915ae01', 'hw');
select th915a_test.ok(
  (select count(*) from public.record_routes where record_item_id = '00000000-0000-4000-8000-00000915a701') = 1,
  'routing: an accepted blood-pressure item reaches Heartwise with its records_import consent');
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a701'', auth.uid(), ''00000000-0000-4000-8000-00000915ae02'', ''sf'')',
  '42501', '%row-level security%', 'routing: ScrollFree receives nothing, even with records_import consent');
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a702'', auth.uid(), ''00000000-0000-4000-8000-00000915ae01'', ''hw'')',
  '42501', '%row-level security%', 'routing: Heartwise does not receive A1C (not its category)');
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a702'', auth.uid(), ''00000000-0000-4000-8000-00000915ae03'', ''st'')',
  '42501', '%row-level security%', 'routing: Steady without records_import consent receives nothing');
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a701'', auth.uid(), ''00000000-0000-4000-8000-00000915ae11'', ''hw'')',
  '42501', '%row-level security%', 'routing: not to another member''s enrolment');
select th915a_test.refused(
  'update public.record_routes set programme_code = ''st''',
  '42501', 'permission denied%', 'routing: routes are never updated');

-- B sees nothing of A ---------------------------------------------------------------------
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0b1'));
select th915a_test.ok(
  (select count(*) from public.record_sources) + (select count(*) from public.record_imports)
  + (select count(*) from public.record_items) + (select count(*) from public.record_routes) = 0,
  'B: sees none of A''s records');
update public.record_items set status = 'rejected';
select th915a_test.act_as(current_setting('th915a.superuser'), null);
select th915a_test.ok(
  (select count(*) from public.record_items
   where user_id = '00000000-0000-4000-8000-00000915a0a1' and status = 'rejected') = 0,
  'B: an update of every item it can see changes none of A''s');
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0b1'));
select th915a_test.refused(
  'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values (''00000000-0000-4000-8000-00000915a701'', auth.uid(), ''00000000-0000-4000-8000-00000915ae11'', ''hw'')',
  '42501', '%row-level security%', 'B: cannot route A''s item to its own enrolment');
select th915a_test.refused(
  'select public.delete_record_source_items(''00000000-0000-4000-8000-00000915a501'', ''DELETE'')',
  'TH029', 'Record source not found', 'B: delete_record_source_items on A''s source is TH029', 'record_source_not_found');

-- delete_record_source_items order of refusals -----------------------------------------------
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.refused(
  'select public.delete_record_source_items(''00000000-0000-4000-8000-00000915a501'', ''delete'')',
  '23514', 'Explicit confirmation required', 'A: a confirmation other than DELETE is 23514');
select th915a_test.act_as('thsync', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.refused(
  'select public.delete_record_source_items(''00000000-0000-4000-8000-00000915a501'', ''DELETE'')',
  'TH010', 'The sync service writes only sync tables', 'sync session: delete_record_source_items is TH010', 'sync_session_refused');
select th915a_test.refused(
  'insert into public.record_items (user_id, source_id, resource_type, code_system, code, display, dedupe_key) values (auth.uid(), ''00000000-0000-4000-8000-00000915a501'', ''Observation'', ''http://loinc.org'', ''1-1'', ''x'', ''synthetic-key-8'')',
  '42501', '%row-level security%', 'sync session: cannot insert record items');
select th915a_test.act_as(current_setting('th915a.superuser'), null);
create role th915a_nobypass nologin;
grant usage on schema public, auth to th915a_nobypass;
grant execute on function auth.uid(), public.sync_writer_session() to th915a_nobypass;
alter function public.delete_record_source_items(uuid, text) owner to th915a_nobypass;
select th915a_test.ok(
  (select not rolsuper and not rolbypassrls from pg_catalog.pg_roles where rolname = 'th915a_nobypass'),
  'setup: th915a_nobypass is neither a superuser nor bypasses row-level security');
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.refused(
  'select public.delete_record_source_items(''00000000-0000-4000-8000-00000915a501'', ''DELETE'')',
  'TH020', 'Account deletion requires a function owner that bypasses row-level security',
  'owner without bypass: delete_record_source_items is TH020', 'rls_bypass_required');
select th915a_test.act_as(current_setting('th915a.superuser'), null);
alter function public.delete_record_source_items(uuid, text) owner to postgres;
select th915a_test.ok(
  th915a_test.counts('00000000-0000-4000-8000-00000915a0a1')
  = '{"record_routes": 1, "record_items": 3, "record_imports": 1, "record_sources": 2}'::jsonb,
  'refusals: nothing of A changed');

-- Truncate guard ---------------------------------------------------------------------------
select th915a_test.refused('truncate public.record_items cascade', 'TH028',
  'Health records are removed only with their source or account', 'superuser: truncate is refused (TH028)', 'record_rows_delete_only');
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.refused('truncate public.record_routes', '42501', 'permission denied%',
  'authenticated: no truncate privilege');

-- A deletes one source's items -------------------------------------------------------------
select set_config('th915a.receipt',
  public.delete_record_source_items('00000000-0000-4000-8000-00000915a501', 'DELETE')::text, true);
select th915a_test.act_as(current_setting('th915a.superuser'), null);
select th915a_test.ok(
  th915a_test.v('receipt')::jsonb = '{"record_routes": 1, "record_items": 2, "record_imports": 1}'::jsonb
  and th915a_test.counts('00000000-0000-4000-8000-00000915a0a1')
      = '{"record_routes": 0, "record_items": 1, "record_imports": 0, "record_sources": 2}'::jsonb,
  'A: delete_record_source_items removes that source''s routes, items and imports; the source and the manual item stay');

-- Delete now removes the enrolment's routes ----------------------------------------------------
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
update public.record_items set status = 'accepted' where id = '00000000-0000-4000-8000-00000915a703';
select th915a_test.act_as(current_setting('th915a.superuser'), null);
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-00000915ae03', 'records_import', 'v1-draft', 'en');
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) values
  ('00000000-0000-4000-8000-00000915a703', auth.uid(), '00000000-0000-4000-8000-00000915ae03', 'st');
select set_config('th915a.now_receipt',
  public.delete_enrolment_now('00000000-0000-4000-8000-00000915ae03', 'DELETE')::text, true);
select th915a_test.act_as(current_setting('th915a.superuser'), null);
select th915a_test.ok(
  (th915a_test.v('now_receipt')::jsonb ->> 'record_routes')::int = 1
  and (select count(*) from pg_catalog.jsonb_object_keys(th915a_test.v('now_receipt')::jsonb)) = 18
  and th915a_test.counts('00000000-0000-4000-8000-00000915a0a1')
      = '{"record_routes": 0, "record_items": 1, "record_imports": 0, "record_sources": 2}'::jsonb,
  'Delete now: counts the enrolment''s route (18 keys); the imported item stays with the account');

-- Account deletion -------------------------------------------------------------------------
select set_config('th915a.b_before', th915a_test.counts('00000000-0000-4000-8000-00000915a0b1')::text, true);
select th915a_test.act_as('authenticator', th915a_test.claims('00000000-0000-4000-8000-00000915a0a1'));
select th915a_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
select th915a_test.refused(
  'insert into public.record_sources (user_id, kind, display_name, status) values (auth.uid(), ''health_connect'', ''Phone'', ''connected'')',
  '42501', '%row-level security%', 'A, deletion started: no new source');
select set_config('th915a.a_receipt', public.delete_my_account('DELETE')::text, true);
select th915a_test.act_as(current_setting('th915a.superuser'), null);
select th915a_test.ok(
  (select count(*) from pg_catalog.jsonb_object_keys(th915a_test.v('a_receipt')::jsonb)) = 28
  and (th915a_test.v('a_receipt')::jsonb ->> 'record_sources')::int = 2
  and (th915a_test.v('a_receipt')::jsonb ->> 'record_items')::int = 1
  and th915a_test.counts('00000000-0000-4000-8000-00000915a0a1')
      = '{"record_routes": 0, "record_items": 0, "record_imports": 0, "record_sources": 0}'::jsonb
  and th915a_test.counts('00000000-0000-4000-8000-00000915a0b1') = th915a_test.v('b_before')::jsonb,
  'account deletion: the receipt has 28 keys and counts A''s records; none is left; B unchanged');

select 'TH915A_SQL_TESTS_COMPLETE' as result;
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

create schema th915a_control;

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000915a0c1', 'synthetic-control-915a@example.test', 'authenticated', 'authenticated');
insert into public.profiles (id)
select '00000000-0000-4000-8000-00000915a0c1'
where not exists (select 1 from public.profiles where id = '00000000-0000-4000-8000-00000915a0c1');
insert into public.enrolments (id, user_id, programme_code, status, mode) values
  ('00000000-0000-4000-8000-00000915aec1', '00000000-0000-4000-8000-00000915a0c1', 'sf', 'focus', 'quit');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-00000915aec1', 'core', 'v1-draft', 'en'),
  ('00000000-0000-4000-8000-00000915aec1', 'records_import', 'v1-draft', 'en');

select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000915a0c1', 'role', 'authenticated')::text, true);
set local role authenticated;
do $c$
declare
  outcome text;
begin
  if pg_catalog.to_regclass('public.record_routes') is null then
    outcome := 'absent';
  else
    begin
      execute 'insert into public.record_sources (user_id, kind, display_name, status) values '
        || '(auth.uid(), ''manual'', ''Entered by you'', ''connected'')';
      execute 'insert into public.record_items (user_id, source_id, resource_type, category, code_system, code, '
        || 'display, value_num, status, dedupe_key) select auth.uid(), s.id, ''Observation'', ''blood_pressure'', '
        || '''http://loinc.org'', ''8480-6'', ''Systolic blood pressure'', 128, ''accepted'', ''synthetic-control-key'' '
        || 'from public.record_sources as s where s.user_id = auth.uid()';
      execute 'insert into public.record_routes (record_item_id, user_id, enrolment_id, programme_code) '
        || 'select i.id, auth.uid(), ''00000000-0000-4000-8000-00000915aec1'', ''sf'' '
        || 'from public.record_items as i where i.user_id = auth.uid()';
      outcome := 'completed';
    exception when others then
      outcome := sqlstate;
    end;
  end if;
  perform pg_catalog.set_config('th915ac.outcome', outcome, true);
  raise notice 'CONTROL route of a blood-pressure item to ScrollFree: %', outcome;
end;
$c$;
reset role;
select set_config('request.jwt.claims', '', true);

select case current_setting('th915ac.outcome')
  when '42501' then 'TH915A_CONTROL_ROUTE_REFUSED'
  when 'absent' then 'TH915A_CONTROL_RECORDS_ABSENT'
  else 'TH915A_CONTROL_UNEXPECTED'
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
  echo "Records migration check failed: $1" >&2
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

for f in "$migration" "$previous" "$owner_check_source" "$contract" "$config"; do
  [[ -f "$f" ]] || fail "missing $f"
done

# Name, version and transaction --------------------------------------------------------------
[[ "${migration##*/}" == 202610180015_records.sql ]] || fail 'the migration is 202610180015_records.sql'
[[ "$(head -n 1 "$migration")" == 'begin;' ]] || fail 'the migration starts with begin;'
[[ "$(tail -n 1 "$migration")" == 'commit;' ]] || fail 'the migration ends with commit;'

# The migration as one statement per line: comments removed, lower case,
# whitespace collapsed.
text=$(sed 's/--.*$//' "$migration" | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' | sed -E 's/ +/ /g')

tables='record_categories record_category_codes record_sources record_imports record_items record_routes'
for t in $tables; do
  grep -Fq "create table public.$t (" <<<"$text" || fail "missing table public.$t"
  grep -Fq "alter table public.$t enable row level security;" <<<"$text" || fail "$t: enable row level security"
  grep -Fq "alter table public.$t force row level security;" <<<"$text" || fail "$t: force row level security"
  grep -Fq "revoke all on table public.$t from public, anon, authenticated, service_role;" <<<"$text" ||
    fail "$t: revoke all from public, anon, authenticated, service_role"
done
[[ "$(grep -o 'create table ' <<<"$text" | wc -l | tr -d ' ')" == 6 ]] || fail 'exactly six tables are created'
for t in record_sources record_imports record_items record_routes; do
  grep -Fq "alter table public.$t enable always trigger ${t}_truncate_guard;" <<<"$text" ||
    fail "$t: truncate guard enabled always"
done
grep -Fq "revoke truncate on public.record_sources, public.record_imports, public.record_items, public.record_routes from public, anon, authenticated, thsync;" <<<"$text" ||
  fail 'truncate is revoked from public, anon, authenticated and thsync'

# Forbidden constructs.
if grep -Eq 'grant [^;]* to [^;]*(anon|service_role|thsync|public)[ ,;]' <<<"$text"; then
  fail 'no grant to anon, service_role, thsync or PUBLIC'
fi
grep -Fq 'grant all' <<<"$text" && fail 'no grant all'
grep -Eq 'disable (row level security|trigger)' <<<"$text" && fail 'nothing is disabled'
grep -Fq 'session_replication_role' <<<"$text" && fail 'no session_replication_role'
grep -Eq ' owner to ' <<<"$text" && fail 'no owner changes'
grep -Eq 'create (or replace )?view' <<<"$text" && fail 'no views'
grep -Eq 'on delete set (null|default)' <<<"$text" && fail 'no foreign key sets null or a default'
grep -Eq 'references public\.(programme_consents|account_consents|consent_documents|sync_[a-z_]+|care_[a-z_]+|caregiver[a-z_]*|supporters)[ (]' <<<"$text" &&
  fail 'no foreign key to consent, sync or care tables'
grep -Eq 'enable always trigger [a-z_]+' <<<"$text" &&
  ! grep -Eq 'enable always trigger record_(sources|imports|items|routes)_truncate_guard' <<<"$text" &&
  fail 'only the truncate guards are enabled always'
grep -Fq 'private.' <<<"$text" && fail 'the token store is not part of this migration'
grep -Eq '^schemas = .*private' "$config" && fail 'schema private must not be exposed in config.toml'

# Every function is followed in the file by its revoke.
while read -r fn; do
  [[ -n "$fn" ]] || continue
  case "$fn" in
    delete_my_app_data|delete_enrolment_now) continue ;;
  esac
  grep -Eq "revoke all on function public\\.$fn\\([^)]*\\) from public, anon, authenticated, service_role;" <<<"$text" ||
    fail "public.$fn must be revoked from public, anon, authenticated and service_role"
done < <(grep -Eo 'create (or replace )?function public\.[a-z_]+' <<<"$text" | sed -E 's/.*public\.//' | sort -u)
grep -Fq 'grant execute on function public.delete_record_source_items(uuid, text) to authenticated;' <<<"$text" ||
  fail 'delete_record_source_items is executable by authenticated'
[[ "$(grep -o 'grant execute' <<<"$text" | wc -l | tr -d ' ')" == 1 ]] || fail 'exactly one grant of execute'

# Policies: the sync guard last; the barrier on inserts only.
for p in record_sources_insert_own record_imports_insert_own record_items_insert_own record_routes_insert_own; do
  body=$(grep -Eo "create policy $p on [^;]*;" <<<"$text") || fail "missing policy $p"
  grep -Fq 'public.deletion_barrier_open() and not public.sync_writer_session() );' <<<"$body" ||
    fail "$p: ends with the deletion barrier and then the sync guard"
done
for p in record_sources_update_own record_imports_update_own record_items_update_own; do
  body=$(grep -Eo "create policy $p on [^;]*;" <<<"$text") || fail "missing policy $p"
  grep -Fq 'deletion_barrier_open' <<<"$body" && fail "$p: updates do not check the barrier"
  [[ "$(grep -o 'and not public.sync_writer_session())' <<<"$body" | wc -l | tr -d ' ')" == 2 ]] ||
    fail "$p: using and with check both end with the sync guard"
done
grep -Fq "public.has_consent(enrolment_id, 'records_import')" <<<"$text" || fail 'routes need records_import consent'
grep -Fq "i.status = 'accepted'" <<<"$text" || fail 'routes need an accepted item'
grep -Fq 'i.category = any (p.receives_resources)' <<<"$text" || fail 'routes need a category the programme receives'

# delete_record_source_items order of refusals.
fn_body=$(sed -n '/^create function public\.delete_record_source_items(/,/^\$\$;/p' "$migration")
line_of() { grep -n -F -- "$1" <<<"$fn_body" | head -n 1 | cut -d: -f1; }
l1=$(line_of "raise insufficient_privilege using message = 'Authentication required';")
l2=$(line_of "raise exception using errcode = 'TH010',")
l3=$(line_of "raise check_violation using message = 'Explicit confirmation required';")
l4=$(line_of "raise exception using errcode = 'TH020',")
l5=$(line_of "raise exception using errcode = 'TH029',")
for l in "$l1" "$l2" "$l3" "$l4" "$l5"; do [[ -n "$l" ]] || fail 'delete_record_source_items: a refusal is missing'; done
((l1 < l2 && l2 < l3 && l3 < l4 && l4 < l5)) ||
  fail 'delete_record_source_items refuses in the order 42501, TH010, 23514, TH020, TH029'
owner_block=$(sed -n '/^  -- The checks and deletes below run as the function owner/,/^  end if;$/p' "$owner_check_source" | sed -n '1,/^  end if;$/p')
grep -Fq -- "$owner_block" <<<"$fn_body" || fail 'delete_record_source_items: the TH020 owner block is the one of 0008, byte for byte'
grep -Fq 'deletion_barrier_open' <<<"$fn_body" && fail 'delete_record_source_items does not check the deletion barrier'

# The two deletion functions are the previous bodies plus only the added lines.
body_of() { sed -n "/^create or replace function public\\.$1(/,/^\\\$\\\$;/p" "$2"; }
added_lines() { diff <(body_of "$1" "$previous") <(body_of "$1" "$migration") | grep -E '^[<>]' || true; }
expected_app=$(cat <<'EOF'
>   deleted_record_routes integer := 0;
>   deleted_record_items integer := 0;
>   deleted_record_imports integer := 0;
>   deleted_record_sources integer := 0;
>   delete from public.record_routes where user_id = caller_id;
>   get diagnostics deleted_record_routes = row_count;
>   delete from public.record_items where user_id = caller_id;
>   get diagnostics deleted_record_items = row_count;
>   delete from public.record_imports where user_id = caller_id;
>   get diagnostics deleted_record_imports = row_count;
>   delete from public.record_sources where user_id = caller_id;
>   get diagnostics deleted_record_sources = row_count;
<     'wellbeing_baseline', deleted_wellbeing_baseline
>     'wellbeing_baseline', deleted_wellbeing_baseline,
>     'record_routes', deleted_record_routes,
>     'record_items', deleted_record_items,
>     'record_imports', deleted_record_imports,
>     'record_sources', deleted_record_sources
EOF
)
[[ "$(added_lines delete_my_app_data)" == "$expected_app" ]] ||
  fail 'delete_my_app_data is the 0013 body plus only the four record tables'
expected_now=$(cat <<'EOF'
>   deleted_record_routes integer := 0;
>   delete from public.record_routes where user_id = caller_id and enrolment_id = p_enrolment_id;
>   get diagnostics deleted_record_routes = row_count;
<     'programme_reminders', deleted_programme_reminders
>     'programme_reminders', deleted_programme_reminders,
>     'record_routes', deleted_record_routes
EOF
)
[[ "$(added_lines delete_enrolment_now)" == "$expected_now" ]] ||
  fail 'delete_enrolment_now is the 0013 body plus only the routes of the enrolment'
now_body=$(body_of delete_enrolment_now "$migration")
routes_line=$(grep -n 'delete from public.record_routes' <<<"$now_body" | cut -d: -f1)
enrolments_line=$(grep -n '^  delete from public.enrolments$' <<<"$now_body" | cut -d: -f1)
if [[ -z "$routes_line" || -z "$enrolments_line" ]] || ((routes_line >= enrolments_line)); then
  fail 'delete_enrolment_now deletes the routes before the enrolment (whose delete would cascade them first)'
fi
grep -Eq '(alter|comment on|grant [^;]* on) function public\.(delete_my_app_data|delete_enrolment_now)' <<<"$text" &&
  fail 'no grant, alter or comment for the deletion functions'

# Registry and contract.
# shellcheck disable=SC2016 # the backticks are literal markdown
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
# shellcheck disable=SC2016
[[ "$(registry_row TH028)" == *'`record_rows_delete_only`'*'Health records are removed only with their source or account |' ]] ||
  fail 'TH028 record_rows_delete_only is in the registry with its message'
# shellcheck disable=SC2016
[[ "$(registry_row TH029)" == *'`record_source_not_found`'*'Record source not found |' ]] ||
  fail 'TH029 record_source_not_found is in the registry with its message'
grep -Fq "hint = 'record_rows_delete_only';" "$migration" || fail 'TH028 is raised with its hint'
grep -Fq "hint = 'record_source_not_found';" "$migration" || fail 'TH029 is raised with its hint'
section=$(sed -n '/^## Health records$/,/^## /p' "$contract")
[[ -n "$section" ]] || fail 'database.md has a Health records section'
grep -Fq 'supabase/migrations/202610180015_records.sql' <<<"$section" || fail 'the section names the migration'
grep -Fq 'records_import' <<<"$section" || fail 'the section states the routing consent'

echo 'Records migration static checks passed.'

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
  echo "$out" | grep -q 'TH915A_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH915A_CONTROL_ROUTE_REFUSED' ||
    fail 'control: a route to a programme that receives no records was not refused'
  echo 'Records migration SQL test and control passed.'
fi
