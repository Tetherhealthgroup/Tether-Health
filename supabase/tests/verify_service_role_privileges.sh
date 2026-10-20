#!/usr/bin/env bash
# Checks that service_role holds nothing in schema public except select on
# public.consent_documents: no other table or column privilege, no execute on
# any function, usage but not create on the schema, no default privileges, and
# no trigger, truncate or references on storage.objects and storage.buckets.
# Account deletion (delete_my_app_data, and the cascade from auth.users) and
# the signup trigger still work.
#
#   bash supabase/tests/verify_service_role_privileges.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the trigger control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test creates and switches to test
#       roles, so the URL's user must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the trigger control
#
# The trigger control tries, as service_role, to add a before-delete trigger
# to enrolments and profiles, then deletes one account with delete_my_app_data
# and one through auth.users. Its result row says which happened:
#   TH988_CONTROL_REFUSED_DELETION_COMPLETED  (expected with the migration)
#   TH988_CONTROL_PLANTED_BLOCKED_TH008       (a tree without the migration)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180006_service_role_least_privilege.sql"
migrations_dir="supabase/migrations"
contract="docs/contracts/database.md"

# The only statement any migration may use to grant service_role anything
# (lower case, one space between words, no trailing semicolon).
allowed_grants=(
  'grant select on table public.consent_documents to service_role'
)

# The consent release gate documented in the contract (between its markers).
release_gate_sql() {
  sed -n '/^<!-- release-gate:begin -->$/,/^<!-- release-gate:end -->$/p' "$contract" |
    sed -e '1,2d' | sed -e '$d' | sed -e '$d'
}

print_sql() {
  local gate line
  gate=$(release_gate_sql)
  [[ -n "$gate" ]] || { echo 'release gate block missing from the contract' >&2; return 1; }
  while IFS= read -r line; do
    if [[ "$line" == '-- @RELEASE_GATE@' ]]; then
      printf '%s\n' "$gate"
    else
      printf '%s\n' "$line"
    fi
  done < <(sql_template)
}

sql_template() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'FAIL setup: this SQL test needs a superuser connection (it creates and switches to test roles)';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role') then
    raise exception 'FAIL setup: role service_role is missing';
  end if;
end;
$setup$;

create schema th988_test;

create function th988_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with p_state and a message like p_message_like.
create function th988_test.refused(
  p_sql text, p_state text, p_message_like text, p_label text
)
returns void language plpgsql set search_path = '' as $f$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate = p_state and sqlerrm like p_message_like then
      raise notice 'PASS % (% %)', p_label, sqlstate, sqlerrm;
      return;
    end if;
    raise exception 'FAIL % (got % %)', p_label, sqlstate, sqlerrm;
  end;
  raise exception 'FAIL % (statement succeeded)', p_label;
end;
$f$;

-- A trigger function anyone may execute, so a refused create trigger shows
-- the missing trigger privilege on the table, not a missing execute.
create function th988_test.planted()
returns trigger language plpgsql set search_path = '' as $f$
begin
  raise exception 'th988 planted trigger fired';
end;
$f$;

-- The table privileges a role can hold on this server (MAINTAIN from 17).
create function th988_test.table_privileges()
returns text[] language sql stable set search_path = '' as $f$
  select array['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER']
    || case when pg_catalog.current_setting('server_version_num')::integer >= 170000
            then array['MAINTAIN'] else array[]::text[] end
$f$;

-- Every privilege p_role holds (directly, through PUBLIC or a role it
-- belongs to) on a table, view, sequence or column in schema public, as
-- "relation:PRIVILEGE" or "relation.column:PRIVILEGE", sorted.
create function th988_test.public_privileges(p_role text)
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(x, ',' order by x), '') from (
    select c.relname || ':' || p.priv as x
    from pg_catalog.pg_class as c
    cross join lateral pg_catalog.unnest(th988_test.table_privileges()) as p(priv)
    where c.relnamespace = 'public'::regnamespace
      and c.relkind in ('r', 'p', 'v', 'm', 'f')
      and pg_catalog.has_table_privilege(p_role, c.oid, p.priv)
    union all
    select c.relname || ':' || p.priv
    from pg_catalog.pg_class as c
    cross join lateral pg_catalog.unnest(array['USAGE', 'SELECT', 'UPDATE']) as p(priv)
    where c.relnamespace = 'public'::regnamespace and c.relkind = 'S'
      and pg_catalog.has_sequence_privilege(p_role, c.oid, p.priv)
    union all
    select c.relname || '.' || a.attname || ':' || p.priv
    from pg_catalog.pg_class as c
    join pg_catalog.pg_attribute as a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    cross join lateral pg_catalog.unnest(array['SELECT', 'INSERT', 'UPDATE', 'REFERENCES']) as p(priv)
    where c.relnamespace = 'public'::regnamespace
      and c.relkind in ('r', 'p', 'v', 'm', 'f')
      and pg_catalog.has_column_privilege(p_role, c.oid, a.attnum, p.priv)
  ) as s
$f$;

-- Every function in schema public that p_role may execute, sorted.
create function th988_test.public_executable(p_role text)
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(p.oid::regprocedure::text, ',' order by p.oid::regprocedure::text), '')
  from pg_catalog.pg_proc as p
  where p.pronamespace = 'public'::regnamespace
    and pg_catalog.has_function_privilege(p_role, p.oid, 'EXECUTE')
$f$;

-- The rows a user holds in every member table, keyed like the
-- delete_my_app_data receipt.
create function th988_test.counts(p_user uuid)
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
    'sync_accounts', (select count(*) from public.sync_account where user_id = p_user))
$f$;

-- The consent release gate, exactly as documented in docs/contracts/database.md
-- (the verify script inserts the documented block here).
create function th988_test.release_gate()
returns table (reason text, purpose text, version text, locale text)
language sql as $f$
-- @RELEASE_GATE@
$f$;

grant usage on schema th988_test to public;
grant execute on all functions in schema th988_test to public;

-- Catalogue: tables, columns, functions, schema, memberships ------------------
select th988_test.ok(
  th988_test.public_privileges('service_role') =
    (select string_agg(x, ',' order by x) from (
       select 'consent_documents:SELECT' as x
       union all
       select 'consent_documents.' || a.attname || ':SELECT'
       from pg_catalog.pg_attribute as a
       where a.attrelid = 'public.consent_documents'::regclass and a.attnum > 0 and not a.attisdropped
     ) as s),
  'service_role: the only privilege on any table, view, sequence or column in public is select on consent_documents');
select th988_test.ok(
  (select coalesce(string_agg(c.relname || ':' || a.privilege_type || ':' || a.is_grantable::text, ','), '')
   from pg_catalog.pg_class as c
   cross join lateral pg_catalog.aclexplode(c.relacl) as a
   where c.relnamespace = 'public'::regnamespace and a.grantee = 'service_role'::regrole)
    = 'consent_documents:SELECT:false'
  and not exists (
    select 1 from pg_catalog.pg_attribute as at
    cross join lateral pg_catalog.aclexplode(at.attacl) as a
    join pg_catalog.pg_class as c on c.oid = at.attrelid
    where c.relnamespace = 'public'::regnamespace and a.grantee = 'service_role'::regrole),
  'service_role: its one grant in public is select on consent_documents, without grant option; no column grants');
select th988_test.ok(
  th988_test.public_executable('service_role') = '',
  'service_role: may execute no function in public');
select th988_test.ok(
  not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(p.proacl) as a
    where p.pronamespace = 'public'::regnamespace and a.grantee = 'service_role'::regrole),
  'service_role: no function in public grants it execute');
select th988_test.ok(
  (select count(*) > 0 and bool_and(not pg_catalog.has_function_privilege('service_role', p.oid, 'EXECUTE'))
   from pg_catalog.pg_proc as p
   where p.pronamespace = 'public'::regnamespace and p.prorettype = 'pg_catalog.trigger'::regtype),
  'service_role: may execute no trigger function in public');
select th988_test.ok(
  not pg_catalog.has_schema_privilege('service_role', 'public', 'CREATE')
  and pg_catalog.has_schema_privilege('service_role', 'public', 'USAGE'),
  'service_role: usage on schema public, no create');
do $members$
declare
  r text;
  present text := '';
begin
  foreach r in array array['authenticated', 'anon', 'pg_write_all_data', 'pg_read_all_data',
                           'pg_maintain', 'postgres'] loop
    if exists (select 1 from pg_catalog.pg_roles where rolname = r) then
      if pg_catalog.pg_has_role('service_role', r, 'MEMBER') then
        raise exception 'FAIL service_role is a member of %', r;
      end if;
      present := present || ' ' || r;
    end if;
  end loop;
  raise notice 'PASS service_role: a member of none of authenticated, anon, pg_write_all_data, pg_read_all_data, pg_maintain, postgres (present:%)', present;
end;
$members$;

-- Storage: the Storage API's privileges stay; trigger, truncate, references go.
select th988_test.ok(
  not pg_catalog.has_table_privilege('service_role', 'storage.objects', 'TRIGGER')
  and not pg_catalog.has_table_privilege('service_role', 'storage.objects', 'TRUNCATE')
  and not pg_catalog.has_table_privilege('service_role', 'storage.objects', 'REFERENCES')
  and not pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'TRIGGER')
  and not pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'TRUNCATE')
  and not pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'REFERENCES'),
  'service_role: no trigger, truncate or references on storage.objects or storage.buckets');
select th988_test.ok(
  pg_catalog.has_table_privilege('service_role', 'storage.objects', 'SELECT, INSERT, UPDATE, DELETE')
  and pg_catalog.has_table_privilege('service_role', 'storage.objects', 'SELECT')
  and pg_catalog.has_table_privilege('service_role', 'storage.objects', 'INSERT')
  and pg_catalog.has_table_privilege('service_role', 'storage.objects', 'UPDATE')
  and pg_catalog.has_table_privilege('service_role', 'storage.objects', 'DELETE')
  and pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'SELECT')
  and pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'INSERT')
  and pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'UPDATE')
  and pg_catalog.has_table_privilege('service_role', 'storage.buckets', 'DELETE'),
  'service_role: keeps select, insert, update and delete on storage.objects and storage.buckets');

-- Default privileges: objects postgres creates in public grant nothing -------------
set local role postgres;
create table public.th988_scratch (id integer primary key, note text);
create sequence public.th988_scratch_seq;
create view public.th988_scratch_view as select id from public.th988_scratch;
create function public.th988_scratch_fn() returns integer language sql as $f$ select 1 $f$;
reset role;
select th988_test.ok(
  not exists (select 1 from pg_catalog.pg_class as c
              cross join lateral pg_catalog.aclexplode(c.relacl) as a
              where c.oid in ('public.th988_scratch'::regclass, 'public.th988_scratch_seq'::regclass,
                              'public.th988_scratch_view'::regclass)
                and a.grantee = 'service_role'::regrole)
  and not exists (select 1 from pg_catalog.pg_proc as p
                  cross join lateral pg_catalog.aclexplode(p.proacl) as a
                  where p.oid = 'public.th988_scratch_fn()'::regprocedure
                    and a.grantee = 'service_role'::regrole),
  'default privileges: a table, sequence, view and function postgres creates in public grant service_role nothing');
select th988_test.ok(
  th988_test.public_privileges('service_role') not like '%th988_scratch%',
  'default privileges: service_role holds no privilege on the new table, its columns, the sequence or the view');
-- Known residual: a function postgres creates in public keeps the built-in
-- execute for PUBLIC (default privileges for a schema only add to it), so
-- service_role may execute it until the creating migration revokes all on
-- the function from public. The catalogue check above is the control.
-- public_residual passes when service_role may execute the function only
-- through PUBLIC ('public'), or may not execute it and the function grants
-- PUBLIC nothing ('absent': an image whose defaults already withhold it). It
-- fails when the function grants execute to service_role or to a role it
-- belongs to (directly or through default privileges), when service_role
-- belongs to the function's owner or to a superuser role, or when
-- service_role may still execute it once PUBLIC's execute is revoked.
create function th988_test.public_residual(p_fn text)
returns text language plpgsql set search_path = '' as $f$
declare
  fn regprocedure := pg_catalog.to_regprocedure(p_fn);
  can_execute boolean;
  public_entry boolean;
  other_path boolean;
begin
  if fn is null then
    raise exception 'FAIL residual: function % is missing', p_fn;
  end if;
  can_execute := pg_catalog.has_function_privilege('service_role', fn, 'EXECUTE');
  select
    coalesce(bool_or(a.grantee = 0), false),
    coalesce(bool_or(a.grantee <> 0 and pg_catalog.pg_has_role('service_role', a.grantee, 'MEMBER')), false)
  into public_entry, other_path
  from pg_catalog.pg_proc as p
  cross join lateral pg_catalog.aclexplode(
    coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
  where p.oid = fn and a.privilege_type = 'EXECUTE';
  -- Membership in the owner, or in a superuser role.
  other_path := other_path
    or pg_catalog.pg_has_role('service_role',
      (select p.proowner from pg_catalog.pg_proc as p where p.oid = fn), 'MEMBER')
    or exists (select 1 from pg_catalog.pg_roles as r
               where r.rolsuper and pg_catalog.pg_has_role('service_role', r.oid, 'MEMBER'));
  -- With PUBLIC's execute revoked, service_role must not be able to execute
  -- it. The revoke is undone with the block.
  begin
    execute pg_catalog.format('revoke execute on function %s from public', fn);
    other_path := other_path or pg_catalog.has_function_privilege('service_role', fn, 'EXECUTE');
    raise exception 'th988 residual probe undone';
  exception when raise_exception then
    if sqlerrm <> 'th988 residual probe undone' then
      raise;
    end if;
  end;
  if other_path then
    raise exception 'FAIL residual: service_role may execute % other than through PUBLIC', fn;
  elsif can_execute and public_entry then
    raise notice 'PASS known residual: service_role may execute % only through PUBLIC until its migration revokes all from public', fn;
    return 'public';
  elsif not can_execute and not public_entry then
    raise notice 'PASS residual absent: the image grants PUBLIC no EXECUTE on new functions; service_role may not execute %', fn;
    return 'absent';
  end if;
  raise exception 'FAIL residual: % (execute %, PUBLIC entry %)', fn, can_execute, public_entry;
end;
$f$;

-- Runs p_sql, then undoes everything it did.
create function th988_test.undone(p_sql text)
returns void language plpgsql set search_path = '' as $f$
begin
  begin
    execute p_sql;
    raise exception 'th988 case undone';
  exception when raise_exception then
    if sqlerrm <> 'th988 case undone' then
      raise;
    end if;
  end;
end;
$f$;

select th988_test.public_residual('public.th988_scratch_fn()');

-- The residual check itself, each case undone afterwards: an image whose
-- defaults withhold PUBLIC's execute gives 'absent'; a direct grant, a role
-- service_role belongs to, default privileges for service_role, membership
-- in a superuser role, and ownership by service_role or a role it belongs to
-- fail.
select th988_test.undone($c$
  alter default privileges for role postgres revoke execute on functions from public;
  set local role postgres;
  create function public.th988_scratch_strict_fn() returns integer language sql as $x$ select 1 $x$;
  reset role;
  select th988_test.ok(
    th988_test.public_residual('public.th988_scratch_strict_fn()') = 'absent',
    'residual check: with PUBLIC execute withheld by default, a new function is reported as residual absent');
$c$);
select th988_test.undone($c$
  grant execute on function public.th988_scratch_fn() to service_role;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: execute granted to service_role directly fails');
$c$);
select th988_test.undone($c$
  create role th988_executor nologin;
  grant execute on function public.th988_scratch_fn() to th988_executor;
  grant th988_executor to service_role;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: execute through a role service_role belongs to fails');
$c$);
select th988_test.undone($c$
  alter default privileges for role postgres in schema public grant execute on functions to service_role;
  set local role postgres;
  create function public.th988_scratch_default_fn() returns integer language sql as $x$ select 1 $x$;
  reset role;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_default_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: execute from default privileges for service_role fails');
$c$);
select th988_test.undone($c$
  create role th988_superuser superuser nologin;
  grant th988_superuser to service_role;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: membership in a superuser role fails');
$c$);
select th988_test.undone($c$
  create role th988_owner nologin;
  grant th988_owner to service_role with inherit false;
  alter function public.th988_scratch_fn() owner to th988_owner;
  revoke execute on function public.th988_scratch_fn() from th988_owner;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: an owner service_role belongs to without inheriting fails');
$c$);
select th988_test.undone($c$
  alter function public.th988_scratch_fn() owner to service_role;
  revoke execute on function public.th988_scratch_fn() from service_role;
  select th988_test.refused('select th988_test.public_residual(''public.th988_scratch_fn()'')',
    'P0001', 'FAIL residual: service_role may execute % other than through PUBLIC',
    'residual check: a function owned by service_role fails');
$c$);

revoke all on function public.th988_scratch_fn() from public;
select th988_test.ok(
  not pg_catalog.has_function_privilege('service_role', 'public.th988_scratch_fn()', 'EXECUTE')
  and position('th988_scratch_fn' in th988_test.public_executable('service_role')) = 0,
  'known residual: once revoked from public, service_role may not execute the new function');
drop function public.th988_scratch_fn();
drop view public.th988_scratch_view;
drop sequence public.th988_scratch_seq;
drop table public.th988_scratch;

-- Behaviour as service_role: member tables ----------------------------------------
-- Every table in public, the consent tables, enrolments, quit_plans,
-- program_data, profiles and sync_* included: insert, update, delete,
-- truncate, create trigger and (except consent_documents) select are refused
-- by the privilege check (42501, permission denied for table).
create function th988_test.table_refusals()
returns text language plpgsql set search_path = '' as $f$
declare
  t record;
  col text;
  stmt text;
  seen text[] := array[]::text[];
begin
  for t in
    select c.oid::regclass::text as rel, c.relname::text as name
    from pg_catalog.pg_class as c
    where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'p')
    order by c.relname
  loop
    select pg_catalog.quote_ident(a.attname) into col
    from pg_catalog.pg_attribute as a
    where a.attrelid = t.rel::regclass and a.attnum > 0 and not a.attisdropped
      and a.attgenerated = '' and a.attidentity = ''
    order by a.attnum limit 1;
    foreach stmt in array array[
      pg_catalog.format('insert into %s default values', t.rel),
      pg_catalog.format('update %s set %s = %s where false', t.rel, col, col),
      pg_catalog.format('delete from %s where false', t.rel),
      pg_catalog.format('truncate %s', t.rel),
      pg_catalog.format('create trigger th988_planted before delete on %s for each row execute function th988_test.planted()', t.rel)
    ] || case when t.name = 'consent_documents' then array[]::text[]
              else array[pg_catalog.format('select 1 from %s limit 1', t.rel)] end
    loop
      perform th988_test.refused(stmt, '42501', 'permission denied for table ' || t.name,
        'service_role: ' || stmt || ' is refused');
    end loop;
    seen := seen || t.name;
  end loop;
  return pg_catalog.array_to_string(seen, ',');
end;
$f$;
grant execute on function th988_test.table_refusals() to public;

set local role service_role;
select set_config('th988.tables', th988_test.table_refusals(), true);
reset role;
select th988_test.ok(
  string_to_array(current_setting('th988.tables'), ',') @> array[
    'programme_consents', 'account_consents', 'consent_documents', 'enrolments', 'quit_plans',
    'program_data', 'profiles', 'sync_account', 'sync_area', 'sync_answer', 'sync_lapse']
  and cardinality(string_to_array(current_setting('th988.tables'), ',')) =
      (select count(*) from pg_catalog.pg_class
       where relnamespace = 'public'::regnamespace and relkind in ('r', 'p')),
  'service_role: the refusals covered every table in public, the member tables included');

set local role service_role;
select th988_test.refused('truncate public.sync_lapse', '42501', 'permission denied for table sync_lapse',
  'service_role: truncate sync_lapse is refused');
select th988_test.refused('truncate public.sync_account cascade', '42501', 'permission denied for table sync_account',
  'service_role: truncate sync_account cascade is refused');
-- The trigger function a planted trigger would borrow: refused on the table.
select th988_test.refused(
  'create trigger th988_planted before delete on public.enrolments for each row execute function public.sync_lapse_append_only()',
  '42501', 'permission denied for table enrolments',
  'service_role: a before delete trigger on enrolments is refused');
select th988_test.refused(
  'create trigger th988_planted before delete on public.profiles for each row execute function public.sync_lapse_append_only()',
  '42501', 'permission denied for table profiles',
  'service_role: a before delete trigger on profiles is refused');
select th988_test.ok(
  (select count(*) >= 0 from public.consent_documents),
  'service_role: select on consent_documents succeeds');

-- Behaviour as service_role: functions --------------------------------------------
select th988_test.refused('select public.delete_my_app_data(''DELETE'')',
  '42501', 'permission denied for function delete_my_app_data',
  'service_role: delete_my_app_data is refused');
select th988_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'permission denied for function begin_account_deletion',
  'service_role: begin_account_deletion is refused');
select th988_test.refused(
  'select public.swap_focus(''00000000-0000-4000-8000-00000988e0f1'', ''00000000-0000-4000-8000-00000988e0f2'')',
  '42501', 'permission denied for function swap_focus',
  'service_role: swap_focus is refused');
select th988_test.refused(
  'select public.supersede_core_consent(''00000000-0000-4000-8000-00000988e0f1'', ''v1-draft'', ''en'')',
  '42501', 'permission denied for function supersede_core_consent',
  'service_role: supersede_core_consent is refused');
select th988_test.refused('select public.save_program_data(''heartwise'', ''{}''::jsonb, 1)',
  '42501', 'permission denied for function save_program_data',
  'service_role: save_program_data is refused');
select th988_test.refused(
  'select public.has_consent(''00000000-0000-4000-8000-00000988e0f1'', ''core'', null)',
  '42501', 'permission denied for function has_consent',
  'service_role: has_consent is refused');
-- The release gate needs the consent tables; it runs as postgres.
select th988_test.refused('select count(*) from th988_test.release_gate()',
  '42501', 'permission denied for table %',
  'service_role: the consent release gate cannot run as service_role');
reset role;
select th988_test.ok(
  (select count(*) >= 0 from th988_test.release_gate()),
  'postgres: the consent release gate runs');

-- Non-regression: deletion and signup ----------------------------------------------
-- A synthetic account with a row in every member table.
create function th988_test.seed(p_user uuid)
returns void language plpgsql set search_path = '' as $f$
declare
  hw uuid;
  st uuid;
begin
  insert into auth.users (id, email, aud, role) values
    (p_user, 'synthetic-' || p_user::text || '@example.test', 'authenticated', 'authenticated');
  insert into public.quit_plans (user_id, quit_date) values (p_user, current_date);
  insert into public.program_data (user_id, program_id, payload) values (p_user, 'heartwise', '{}');
  insert into public.enrolments (user_id, programme_code, status)
  values (p_user, 'hw', 'focus') returning id into hw;
  insert into public.enrolments (user_id, programme_code, status)
  values (p_user, 'st', 'learn_only') returning id into st;
  insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
    (hw, 'core', 'v1-draft', 'en'), (hw, 'reminders', 'v1-draft', 'en'), (st, 'core', 'v1-draft', 'es');
  insert into public.account_consents (user_id, purpose, consent_version, locale) values
    (p_user, 'essential', 'v1-draft', 'en');
  insert into public.sync_account (user_id) values (p_user);
  insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
  values (p_user, hw, 'hw', 1, 1);
  insert into public.sync_answer (user_id, programme_code, screen_id, payload)
  values (p_user, 'hw', 'hw_targets', '{"slider":{"0":120}}');
  insert into public.sync_lapse (user_id, programme_code, ordinal, at)
  values (p_user, 'hw', 0, now());
end;
$f$;

select th988_test.seed('00000000-0000-4000-8000-0000009880a1');
select th988_test.seed('00000000-0000-4000-8000-0000009880b1');
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
select th988_test.ok(
  th988_test.counts('00000000-0000-4000-8000-0000009880a1') = '{"profiles": 1, "quit_plans": 1,
    "program_data": 1, "enrolments": 2, "programme_consents": 3, "account_consents": 1,
    "sync_answers": 1, "sync_lapses": 1, "sync_areas": 1, "sync_accounts": 1}'::jsonb
  and th988_test.counts('00000000-0000-4000-8000-0000009880b1') =
      th988_test.counts('00000000-0000-4000-8000-0000009880a1'),
  'setup: synthetic A and B each hold a row in every member table');

-- A: delete_my_app_data through the API path (authenticated, A's token).
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000009880a1', true);
select set_config('request.jwt.claims', json_build_object(
  'sub', '00000000-0000-4000-8000-0000009880a1', 'role', 'authenticated',
  'amr', json_build_array(json_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
select set_config('th988.a_before', th988_test.counts('00000000-0000-4000-8000-0000009880a1')::text, true);
set local role authenticated;
select th988_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
select set_config('th988.a_receipt', public.delete_my_app_data('DELETE')::text, true);
reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '', true);
select th988_test.ok(
  current_setting('th988.a_receipt')::jsonb = current_setting('th988.a_before')::jsonb,
  'A: delete_my_app_data returns the same counts as the rows A held');
select th988_test.ok(
  (select bool_and(value = '0'::jsonb)
   from jsonb_each(th988_test.counts('00000000-0000-4000-8000-0000009880a1'))),
  'A: no row of A is left in any member table');

-- B: the account's auth.users row is deleted by a role with no privilege in
-- public (as Auth admin does); the cascade still removes every member row.
create role th988_auth_admin nologin;
grant usage on schema auth to th988_auth_admin;
grant select, insert, delete on auth.users to th988_auth_admin;
select th988_test.ok(
  th988_test.public_privileges('th988_auth_admin') = ''
  and th988_test.public_executable('th988_auth_admin') = '',
  'auth admin stand-in: holds no table, column or function privilege in public');
set local role th988_auth_admin;
delete from auth.users where id = '00000000-0000-4000-8000-0000009880b1';
reset role;
select th988_test.ok(
  (select bool_and(value = '0'::jsonb)
   from jsonb_each(th988_test.counts('00000000-0000-4000-8000-0000009880b1')))
  and not exists (select 1 from auth.users where id = '00000000-0000-4000-8000-0000009880b1'),
  'B: deleting the auth.users row cascades to zero rows in every member table');

-- Signup: an auth.users insert by the same role still creates the profile.
set local role th988_auth_admin;
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009880c1', 'synthetic-user-c1@example.test',
   'authenticated', 'authenticated');
reset role;
select th988_test.ok(
  (select count(*) from public.profiles where id = '00000000-0000-4000-8000-0000009880c1') = 1,
  'C: an auth.users insert still creates the profile');

select 'TH988_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

print_control_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'control: needs a superuser connection';
  end if;
end;
$setup$;

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009881a1', 'synthetic-control-a1@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009881b1', 'synthetic-control-b1@example.test',
   'authenticated', 'authenticated');
insert into public.enrolments (user_id, programme_code, status) values
  ('00000000-0000-4000-8000-0000009881a1', 'hw', 'focus'),
  ('00000000-0000-4000-8000-0000009881b1', 'hw', 'focus');
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;

-- service_role tries to add a before-delete trigger to enrolments and
-- profiles, borrowing a trigger function that always raises (TH008).
set local role service_role;
do $plant$
declare
  t text;
begin
  foreach t in array array['enrolments', 'profiles'] loop
    begin
      execute pg_catalog.format(
        'create trigger th988_planted before delete on public.%I for each row execute function public.sync_lapse_append_only()', t);
      perform pg_catalog.set_config('th988c.plant_' || t, 'planted', true);
    exception when insufficient_privilege then
      perform pg_catalog.set_config('th988c.plant_' || t, 'refused', true);
    end;
    raise notice 'CONTROL service_role create trigger on %: %', t,
      pg_catalog.current_setting('th988c.plant_' || t);
  end loop;
end;
$plant$;
reset role;

-- A: delete_my_app_data through the API path.
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000009881a1', true);
select set_config('request.jwt.claims', json_build_object(
  'sub', '00000000-0000-4000-8000-0000009881a1', 'role', 'authenticated',
  'amr', json_build_array(json_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
set local role authenticated;
do $delete$
begin
  perform public.begin_account_deletion('DELETE');
  begin
    perform public.delete_my_app_data('DELETE');
    perform pg_catalog.set_config('th988c.delete_my_app_data', 'completed', true);
  exception when others then
    perform pg_catalog.set_config('th988c.delete_my_app_data', sqlstate, true);
  end;
  raise notice 'CONTROL delete_my_app_data: %', pg_catalog.current_setting('th988c.delete_my_app_data');
end;
$delete$;
reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '', true);

-- B: auth.users delete by a role with no privilege in public.
create role th988_control_auth nologin;
grant usage on schema auth to th988_control_auth;
grant select, delete on auth.users to th988_control_auth;
set local role th988_control_auth;
do $cascade$
begin
  begin
    delete from auth.users where id = '00000000-0000-4000-8000-0000009881b1';
    perform pg_catalog.set_config('th988c.cascade', 'completed', true);
  exception when others then
    perform pg_catalog.set_config('th988c.cascade', sqlstate, true);
  end;
  raise notice 'CONTROL auth.users delete cascade: %', pg_catalog.current_setting('th988c.cascade');
end;
$cascade$;
reset role;

select set_config('th988c.remaining', (
  (select count(*) from public.enrolments where user_id in
     ('00000000-0000-4000-8000-0000009881a1', '00000000-0000-4000-8000-0000009881b1'))
  + (select count(*) from public.profiles where id in
     ('00000000-0000-4000-8000-0000009881a1', '00000000-0000-4000-8000-0000009881b1')))::text, true);
do $report$
begin
  raise notice 'CONTROL remaining enrolment and profile rows of A and B: %',
    pg_catalog.current_setting('th988c.remaining');
end;
$report$;

select case
  when current_setting('th988c.plant_enrolments') = 'planted'
   and current_setting('th988c.plant_profiles') = 'planted'
   and current_setting('th988c.delete_my_app_data') = 'TH008'
   and current_setting('th988c.cascade') = 'TH008'
   and current_setting('th988c.remaining') = '4'
    then 'TH988_CONTROL_PLANTED_BLOCKED_TH008'
  when current_setting('th988c.plant_enrolments') = 'refused'
   and current_setting('th988c.plant_profiles') = 'refused'
   and current_setting('th988c.delete_my_app_data') = 'completed'
   and current_setting('th988c.cascade') = 'completed'
   and current_setting('th988c.remaining') = '0'
    then 'TH988_CONTROL_REFUSED_DELETION_COMPLETED'
  else 'TH988_CONTROL_UNEXPECTED'
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
  echo "service_role privilege check failed: $1" >&2
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

# Prints every statement on stdin that grants service_role anything (a
# privilege, a role, default privileges, or a grant run through execute) and
# is not on the allowlist, one per line.
service_role_grants() {
  local stmt allowed ok
  while IFS= read -r stmt; do
    [[ "$stmt" =~ ^revoke\  ]] && continue
    grep -Eq '(^|[^a-z0-9_$])grant([^a-z0-9_$]|$)' <<<"$stmt" || continue
    grep -Eq '(^|[^a-z0-9_$])service_role([^a-z0-9_$]|$)' <<<"$stmt" || continue
    ok=0
    for allowed in "${allowed_grants[@]}"; do
      [[ "$stmt" == "$allowed" ]] && ok=1
    done
    ((ok)) || printf '%s\n' "$stmt"
  done < <(statements)
}

# Self-test of the scan; runs every time.
check_scan() {
  local want="$1" got
  shift
  got=$(printf '%s\n' "$@" | service_role_grants)
  [[ "$got" == "$want" ]] || fail "grant scan self-test: expected '$want', got '$got' for: $*"
}
check_scan 'grant select on public.profiles to service_role' 'grant select on public.profiles to service_role;'
check_scan 'grant all on all tables in schema public to service_role' \
  'GRANT ALL' '  ON ALL TABLES IN SCHEMA public' '  TO "service_role";'
check_scan 'grant execute on function public.f() to authenticated, service_role' \
  'grant execute on function public.f() to authenticated, service_role; -- reviewed'
check_scan 'alter default privileges in schema public grant select on tables to service_role' \
  'alter default privileges in schema public grant select on tables to service_role;'
check_scan 'alter default privileges for role postgres in schema public grant all on functions to service_role' \
  'alter default privileges for role postgres in schema public' '  grant all on functions to service_role;'
check_scan "do \$\$ begin execute 'grant insert on public.t to service_role'" \
  "do \$\$ begin execute 'grant insert on public.t to service_role'; end \$\$;"
check_scan 'grant service_role to authenticator' 'grant service_role to authenticator;'
check_scan 'grant select, insert on table public.consent_documents to service_role' \
  'grant select, insert on table public.consent_documents to service_role;'
check_scan '' 'grant select on table public.consent_documents to service_role;' \
  'revoke all on all tables in schema public from service_role;' \
  'revoke grant option for select on public.t from service_role;' \
  'grant select on public.t to authenticated; -- not service_role' \
  'grant select on public.service_roles to authenticated;' \
  'alter default privileges for role postgres in schema public revoke all on tables from service_role;'

for f in "${migration_files[@]}"; do
  problem=$(service_role_grants <"$f")
  [[ -z "$problem" ]] || fail "$f grants service_role more than select on consent_documents: $problem"
done

# The migration: exactly these statements, in this order.
expected_statements='begin
revoke all on all tables in schema public from service_role
revoke all on all sequences in schema public from service_role
grant select on table public.consent_documents to service_role
revoke all on all routines in schema public from service_role
revoke create on schema public from service_role
alter default privileges for role postgres in schema public revoke all on tables from service_role
alter default privileges for role postgres in schema public revoke all on functions from service_role
alter default privileges for role postgres in schema public revoke all on sequences from service_role
revoke trigger, truncate, references on storage.objects, storage.buckets from service_role
commit'
[[ "$(statements <"$migration")" == "$expected_statements" ]] ||
  fail "$migration must contain exactly the service_role revokes, the consent_documents select grant and the default privilege revokes, in order"

# The contract states the scope and that the release gate runs as postgres.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
grep -Fxq '## service_role' "$contract" || fail "$contract must have a service_role section"
# shellcheck disable=SC2016
grep -Fq '`service_role` holds `select` on `consent_documents` and nothing else' "$contract" ||
  fail "$contract must state that service_role holds select on consent_documents and nothing else in public"
gate_prose=$(sed -n '/^### Consent release gate$/,/^<!-- release-gate:begin -->$/p' "$contract" |
  tr '\n' ' ' | sed -E 's/ +/ /g')
[[ -n "$gate_prose" ]] || fail "$contract must keep the consent release gate section"
# shellcheck disable=SC2016
grep -Fq 'Run it as `postgres`.' <<<"$gate_prose" ||
  fail 'the consent release gate must run as postgres'
# shellcheck disable=SC2016
if grep -Eq 'such as `postgres` or `service_role`|or `service_role`;' <<<"$gate_prose"; then
  fail 'the consent release gate must not offer service_role as a role to run it'
fi

echo 'service_role privilege static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  run_psql() {
    env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
      psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1
  }
  out=$(print_sql | run_psql) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH988_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'trigger control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH988_CONTROL_REFUSED_DELETION_COMPLETED' ||
    fail 'trigger control: service_role could add a trigger or deletion did not complete'
  echo 'service_role privilege SQL test and trigger control passed.'
fi
