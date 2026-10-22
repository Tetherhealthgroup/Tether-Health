#!/usr/bin/env bash
# Checks that public.delete_my_app_data may be executed by its owner only.
# Members reach it through public.delete_my_account, which runs as that owner
# and also deletes the Auth identity. The migration revokes execute from
# PUBLIC, anon and authenticated and replaces the function comment; nothing
# else changes, and no later migration grants execute on it again.
#
#   bash supabase/tests/verify_app_data_deletion_owner_only.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator and creates a test role, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: as
#       authenticated, one synthetic member with deletion started and one
#       without a profile row call delete_my_app_data directly, and it reports:
#         TH988F_CONTROL_DIRECT_CALL_REFUSED    (expected with the migration:
#             both calls are refused with 42501 and delete nothing)
#         TH988F_CONTROL_DIRECT_CALL_COMPLETED  (a tree without the migration:
#             both calls complete and delete the members' rows)
#         TH988F_CONTROL_UNEXPECTED             (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180010_app_data_deletion_owner_only.sql"
migrations_dir="supabase/migrations"
contract="docs/contracts/database.md"
expected_comment='Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.'

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
  if pg_catalog.to_regprocedure('auth.jwt()') is null or pg_catalog.to_regclass('storage.objects') is null
     or pg_catalog.to_regprocedure('public.delete_my_account(text)') is null then
    raise exception 'FAIL setup: auth.jwt(), storage.objects and public.delete_my_account(text) are needed';
  end if;
end;
$setup$;

select set_config('th988f.superuser', session_user, true);

create schema th988f_test;

create function th988f_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with p_state and a message like p_message_like.
create function th988f_test.refused(p_sql text, p_state text, p_message_like text, p_label text)
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

-- Token claims for p_sub with one password sign-in 30 seconds ago.
create function th988f_test.claims(p_sub text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object('role', 'authenticated', 'aud', 'authenticated', 'sub', p_sub,
    'amr', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - 30)))::text
$f$;

-- Switches the session to p_login acting as authenticated with p_claims, the
-- way PostgREST (authenticator) and the sync service (thsync) do; or back to
-- the superuser that started the test. No SET clause on purpose: SET LOCAL
-- inside a function with one would be undone when it returns.
create function th988f_test.act_as(p_login text, p_claims text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th988f.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

-- The rows a user holds in every member table, keyed like the
-- delete_my_app_data receipt.
create function th988f_test.counts(p_user uuid)
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
    'observations', (select count(*) from public.observations where user_id = p_user),
    'programme_entries', (select count(*) from public.programme_entries where user_id = p_user),
    'rescue_events', (select count(*) from public.rescue_events where user_id = p_user),
    'lesson_progress', (select count(*) from public.lesson_progress where user_id = p_user),
    'programme_reminders', (select count(*) from public.programme_reminders where user_id = p_user),
    'notification_preferences', (select count(*) from public.notification_preferences where user_id = p_user),
    'wellbeing_baseline', (select count(*) from public.wellbeing_baseline where user_id = p_user))
$f$;

-- Member rows plus the identity and whether account deletion was started.
create function th988f_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select th988f_test.counts(p_user) || pg_catalog.jsonb_build_object(
    'users', (select count(*) from auth.users where id = p_user),
    'deletion_started', (select account_deletion_started_at is not null
                         from public.profiles where id = p_user))
$f$;

-- A synthetic account with an identity and a row in every member table.
create function th988f_test.seed(p_user uuid)
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

grant usage on schema th988f_test to public;
grant execute on all functions in schema th988f_test to public;
revoke all on function th988f_test.seed(uuid) from public;

-- Catalogue -------------------------------------------------------------------
create role th988f_plain nologin;
select th988f_test.ok(
  not pg_catalog.has_function_privilege('authenticated', 'public.delete_my_app_data(text)', 'EXECUTE'),
  'delete_my_app_data: authenticated may not execute it');
select th988f_test.ok(
  not pg_catalog.has_function_privilege('anon', 'public.delete_my_app_data(text)', 'EXECUTE'),
  'delete_my_app_data: anon may not execute it');
select th988f_test.ok(
  not pg_catalog.has_function_privilege('thsync', 'public.delete_my_app_data(text)', 'EXECUTE'),
  'delete_my_app_data: thsync may not execute it');
select th988f_test.ok(
  not pg_catalog.has_function_privilege('service_role', 'public.delete_my_app_data(text)', 'EXECUTE'),
  'delete_my_app_data: service_role may not execute it');
select th988f_test.ok(
  not pg_catalog.has_function_privilege('th988f_plain', 'public.delete_my_app_data(text)', 'EXECUTE'),
  'delete_my_app_data: a fresh role with only PUBLIC may not execute it');
select th988f_test.ok(
  (select pg_catalog.has_function_privilege(proowner, 'public.delete_my_app_data(text)', 'EXECUTE')
     and proowner = (select proowner from pg_catalog.pg_proc
                     where oid = 'public.delete_my_app_data(text)'::regprocedure)
   from pg_catalog.pg_proc where oid = 'public.delete_my_account(text)'::regprocedure),
  'delete_my_app_data: the owner of delete_my_account owns it and may execute it');
select th988f_test.ok(
  (select string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ','
                     order by a.grantee::regrole::text)
   from pg_catalog.pg_proc as p
   cross join lateral pg_catalog.aclexplode(
     coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
   where p.oid = 'public.delete_my_app_data(text)'::regprocedure)
  = (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
     where oid = 'public.delete_my_app_data(text)'::regprocedure) || ':EXECUTE',
  'delete_my_app_data: the only privilege entry is its owner''s; no PUBLIC entry');
select th988f_test.ok(
  pg_catalog.obj_description('public.delete_my_app_data(text)'::regprocedure, 'pg_proc')
  = 'Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.',
  'delete_my_app_data: the function comment says only its owner may execute it');

-- Synthetic accounts ------------------------------------------------------------
-- A: deletion started with a recent sign-in. B: no profile row.
select th988f_test.seed('00000000-0000-4000-8000-00000988f0a1');
select th988f_test.seed('00000000-0000-4000-8000-00000988f0b1');
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
delete from public.profiles where id = '00000000-0000-4000-8000-00000988f0b1';
select set_config('th988f.a_seeded', th988f_test.counts('00000000-0000-4000-8000-00000988f0a1')::text, true);
select th988f_test.ok(
  current_setting('th988f.a_seeded')::jsonb = '{"profiles": 1, "quit_plans": 1,
    "program_data": 1, "enrolments": 2, "programme_consents": 3, "account_consents": 1,
    "sync_answers": 1, "sync_lapses": 1, "sync_areas": 1, "sync_accounts": 1,
    "care_share_access": 0, "care_messages": 0, "care_shares": 0, "caregiver_events": 0,
    "caregivers": 0, "care_connections": 0, "supporters": 0,
    "observations": 0, "programme_entries": 0, "rescue_events": 0, "lesson_progress": 0,
    "programme_reminders": 0, "notification_preferences": 0, "wellbeing_baseline": 0}'::jsonb
  and th988f_test.counts('00000000-0000-4000-8000-00000988f0b1') =
    current_setting('th988f.a_seeded')::jsonb || '{"profiles": 0, "quit_plans": 0}'::jsonb,
  'setup: synthetic A holds a row in every member table except the care tables (verify_care_migration.sh covers them); B the same without a profile or quit plan');

select th988f_test.act_as('authenticator', th988f_test.claims('00000000-0000-4000-8000-00000988f0a1'));
select th988f_test.ok(public.begin_account_deletion('DELETE'),
  'A API: begin_account_deletion sets the deletion barrier (recent sign-in)');
select th988f_test.act_as(current_setting('th988f.superuser'), null);
select set_config('th988f.a_ready', th988f_test.state('00000000-0000-4000-8000-00000988f0a1')::text, true);
select set_config('th988f.b_ready', th988f_test.state('00000000-0000-4000-8000-00000988f0b1')::text, true);
select th988f_test.ok(
  current_setting('th988f.a_ready')::jsonb =
    current_setting('th988f.a_seeded')::jsonb || '{"users": 1, "deletion_started": true}'::jsonb
  and current_setting('th988f.b_ready')::jsonb ->> 'users' = '1'
  and current_setting('th988f.b_ready')::jsonb -> 'deletion_started' = 'null'::jsonb,
  'setup: A has deletion started; B has an identity and no profile row');

-- Direct calls are refused ----------------------------------------------------------
select th988f_test.act_as('authenticator', th988f_test.claims('00000000-0000-4000-8000-00000988f0a1'));
select th988f_test.refused('select public.delete_my_app_data(''DELETE'')',
  '42501', 'permission denied for function delete_my_app_data',
  'A API, deletion started, recent sign-in: a direct call is refused');
select th988f_test.act_as('authenticator', th988f_test.claims('00000000-0000-4000-8000-00000988f0b1'));
select th988f_test.refused('select public.delete_my_app_data(''DELETE'')',
  '42501', 'permission denied for function delete_my_app_data',
  'B API, no profile row, recent sign-in: a direct call is refused');
select th988f_test.act_as('thsync', th988f_test.claims('00000000-0000-4000-8000-00000988f0a1'));
select th988f_test.ok(session_user = 'thsync' and current_user = 'authenticated'
  and auth.uid() = '00000000-0000-4000-8000-00000988f0a1' and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th988f_test.refused('select public.delete_my_app_data(''DELETE'')',
  '42501', 'permission denied for function delete_my_app_data',
  'A sync session: a direct call is refused');
select th988f_test.act_as(current_setting('th988f.superuser'), null);
select th988f_test.ok(
  th988f_test.state('00000000-0000-4000-8000-00000988f0a1') = current_setting('th988f.a_ready')::jsonb
  and th988f_test.state('00000000-0000-4000-8000-00000988f0b1') = current_setting('th988f.b_ready')::jsonb,
  'A and B: the refused calls changed no member-table row and no identity');

-- The owner path still deletes everything ------------------------------------------
select th988f_test.act_as('authenticator', th988f_test.claims('00000000-0000-4000-8000-00000988f0a1'));
select set_config('th988f.a_receipt', public.delete_my_account('DELETE')::text, true);
select th988f_test.act_as(current_setting('th988f.superuser'), null);
select th988f_test.ok(
  current_setting('th988f.a_receipt')::jsonb = current_setting('th988f.a_seeded')::jsonb,
  'A API: delete_my_account returns counts equal to A''s seeded rows');
select th988f_test.ok(
  th988f_test.state('00000000-0000-4000-8000-00000988f0a1') = '{"profiles": 0, "quit_plans": 0,
    "program_data": 0, "enrolments": 0, "programme_consents": 0, "account_consents": 0,
    "sync_answers": 0, "sync_lapses": 0, "sync_areas": 0, "sync_accounts": 0,
    "care_share_access": 0, "care_messages": 0, "care_shares": 0, "caregiver_events": 0,
    "caregivers": 0, "care_connections": 0, "supporters": 0,
    "observations": 0, "programme_entries": 0, "rescue_events": 0, "lesson_progress": 0,
    "programme_reminders": 0, "notification_preferences": 0, "wellbeing_baseline": 0,
    "users": 0, "deletion_started": null}'::jsonb,
  'A: no member row and no identity of A is left');
select th988f_test.ok(
  th988f_test.state('00000000-0000-4000-8000-00000988f0b1') = current_setting('th988f.b_ready')::jsonb,
  'B: untouched by A''s deletion');

select 'TH988F_SQL_TESTS_COMPLETE' as result;
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

create schema th988f_control;

-- Synthetic C (deletion will be started) and D (no profile row), each with
-- program data.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000988f0c1', 'synthetic-control-c1@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-00000988f0d1', 'synthetic-control-d1@example.test', 'authenticated', 'authenticated');
insert into public.program_data (user_id, program_id, payload) values
  ('00000000-0000-4000-8000-00000988f0c1', 'heartwise', '{}'),
  ('00000000-0000-4000-8000-00000988f0d1', 'heartwise', '{}');
delete from public.profiles where id = '00000000-0000-4000-8000-00000988f0d1';

-- C starts deletion with a recent sign-in, then each member calls
-- delete_my_app_data directly as authenticated. The outcome is "completed" or
-- the SQLSTATE that refused it.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000988f0c1', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
set local role authenticated;
select public.begin_account_deletion('DELETE') as begun;
do $c$
declare
  outcome text;
begin
  begin
    perform public.delete_my_app_data('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988fc.c', outcome, true);
  raise notice 'CONTROL direct delete_my_app_data, deletion started: %', outcome;
end;
$c$;
reset role;

select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000988f0d1', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
set local role authenticated;
do $d$
declare
  outcome text;
begin
  begin
    perform public.delete_my_app_data('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988fc.d', outcome, true);
  raise notice 'CONTROL direct delete_my_app_data, no profile row: %', outcome;
end;
$d$;
reset role;
select set_config('request.jwt.claims', '', true);

select set_config('th988fc.remaining', (
  (select count(*) from public.program_data where user_id in
     ('00000000-0000-4000-8000-00000988f0c1', '00000000-0000-4000-8000-00000988f0d1'))
  + (select count(*) from public.profiles where id in
     ('00000000-0000-4000-8000-00000988f0c1', '00000000-0000-4000-8000-00000988f0d1')))::text, true);
do $report$
begin
  raise notice 'CONTROL remaining program data and profile rows of C and D: %',
    pg_catalog.current_setting('th988fc.remaining');
end;
$report$;

select case
  when current_setting('th988fc.c') = '42501'
   and current_setting('th988fc.d') = '42501'
   and current_setting('th988fc.remaining') = '3'
    then 'TH988F_CONTROL_DIRECT_CALL_REFUSED'
  when current_setting('th988fc.c') = 'completed'
   and current_setting('th988fc.d') = 'completed'
   and current_setting('th988fc.remaining') = '0'
    then 'TH988F_CONTROL_DIRECT_CALL_COMPLETED'
  else 'TH988F_CONTROL_UNEXPECTED'
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
  echo "App data deletion owner-only check failed: $1" >&2
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

for f in "$migration" "$contract"; do
  [[ -f "$f" ]] || fail "missing $f"
done
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

# The migration name follows the convention (12-digit version, lowercase name).
[[ "${migration##*/}" =~ ^[0-9]{12}_[a-z0-9_]+\.sql$ ]] ||
  fail "${migration##*/} is not YYYYMMDDNNNN_name.sql"

migration_files=()
while IFS= read -r -d '' path; do
  migration_files+=("$path")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -name '*.sql' -print0 | LC_ALL=C sort -z)

# The SQL on stdin as one statement per line: comments removed, whitespace
# collapsed to single spaces, split at ";". statements() also lower-cases and
# drops double quotes.
normalized() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | sed -E 's/ +/ /g' | tr ';' '\n' |
    sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}
statements() {
  normalized | tr '[:upper:]' '[:lower:]' | tr -d '"'
}

# The comment text must stay one statement for every statement splitter in
# these checks: no ";", no "--", and no standalone word grant or revoke.
[[ "$expected_comment" != *';'* && "$expected_comment" != *'--'* ]] ||
  fail 'the expected comment must contain no ";" and no "--"'
if grep -Eiq '(^|[^a-z_])(grant|revoke)([^a-z_]|$)' <<<"$expected_comment"; then
  fail 'the expected comment must not contain the word grant or revoke'
fi

# The migration: exactly these statements. Nothing is created, replaced,
# altered, dropped or granted, and the owner is not changed.
outline=$(statements <"$migration")
expected_lower=$(tr '[:upper:]' '[:lower:]' <<<"$expected_comment")
expected_outline="begin
revoke all on function public.delete_my_app_data(text) from public, anon, authenticated
comment on function public.delete_my_app_data(text) is '$expected_lower'
commit"
[[ "$outline" == "$expected_outline" ]] ||
  fail "$migration must contain exactly: begin, the revoke of execute on delete_my_app_data from public, anon and authenticated, the new function comment, commit. Got:
$outline"
# The comment, with its exact case.
normalized <"$migration" |
  grep -Fxq "comment on function public.delete_my_app_data(text) is '$expected_comment'" ||
  fail "the comment on delete_my_app_data in $migration must be exactly: $expected_comment"

# No later migration grants execute on it again.
seen=0
later=''
for f in "${migration_files[@]}"; do
  if [[ "$f" == "$migration" ]]; then
    seen=1
    continue
  fi
  ((seen)) || continue
  if statements <"$f" | grep -E '(^| )grant ' | grep -q 'delete_my_app_data'; then
    later+=" $f"
  fi
done
((seen)) || fail "$migration is not among the migrations"
[[ -z "$later" ]] || fail "no migration after $migration may grant on delete_my_app_data (found in:$later)"

# The latest comment on it is this migration's, and no longer calls identity
# deletion a separate privileged operation.
latest_comment=''
for f in "${migration_files[@]}"; do
  if statements <"$f" | grep -q '^comment on function public\.delete_my_app_data(text) is '; then
    latest_comment="$f"
  fi
done
[[ "$latest_comment" == "$migration" ]] ||
  fail "the latest comment on delete_my_app_data must be in $migration (found: ${latest_comment:-nothing})"
if statements <"$migration" | grep '^comment on function public\.delete_my_app_data(text) is ' |
  grep -q 'privileged operation'; then
  fail 'the comment on delete_my_app_data must no longer say "privileged operation"'
fi

# Contract.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_app_data_deletion_owner_only.sh`' "$contract" ||
  fail "$contract must name this check"

echo 'App data deletion owner-only static checks passed.'

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
  echo "$out" | grep -q 'TH988F_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH988F_CONTROL_DIRECT_CALL_REFUSED' ||
    fail 'control: a direct call to delete_my_app_data as authenticated was not refused'
  echo 'App data deletion owner-only SQL test and control passed.'
fi
