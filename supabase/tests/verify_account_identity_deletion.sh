#!/usr/bin/env bash
# Checks public.delete_my_account: the signed-in member deletes their app data
# and their auth.users row in one call, with their own token. It takes no user
# id, is security definer with an empty search_path, may be executed by
# authenticated only, and refuses in this order: no caller (42501), a sync
# service session (TH010), a confirmation other than DELETE (23514), a sign-in
# that is not recent by the token's amr claim (TH017), avatar objects left
# under the caller's folder (TH016). It then calls delete_my_app_data
# unchanged, deletes the caller's auth.users row, raises TH018 if that row is
# still there, and returns delete_my_app_data's counts. It never deletes
# storage rows.
#
#   bash supabase/tests/verify_account_identity_deletion.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator and creates test roles, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: for one
#       synthetic account it calls delete_my_account with an avatar object
#       left, then with a delete of the auth.users row that silently removes
#       nothing (a before-delete trigger that skips the row), and reports
#       each outcome:
#         TH988B_CONTROL_REFUSED_TH016_TH018   (expected with the migration)
#         TH988B_CONTROL_FUNCTION_ABSENT       (a tree without the migration)
#         TH988B_CONTROL_STORAGE_CHECK_MISSING / TH988B_CONTROL_RECHECK_MISSING
#             (the avatar check or the post-delete check was removed)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180008_delete_my_account.sql"
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
  if pg_catalog.to_regclass('auth.identities') is null or pg_catalog.to_regclass('auth.sessions') is null
     or pg_catalog.to_regclass('storage.objects') is null
     or pg_catalog.to_regprocedure('auth.jwt()') is null then
    raise exception 'FAIL setup: auth.identities, auth.sessions, storage.objects and auth.jwt() are needed';
  end if;
end;
$setup$;

select set_config('th988b.superuser', session_user, true);

create schema th988b_test;

create function th988b_test.ok(p_cond boolean, p_label text)
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
create function th988b_test.refused(
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

-- An amr claim with one password sign-in p_age seconds before now()
-- (negative: in the future).
create function th988b_test.amr_at(p_age numeric)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - p_age))
$f$;

-- Token claims for p_sub; a null p_sub or p_amr leaves that claim out.
create function th988b_test.claims(p_sub text, p_amr jsonb)
returns text language sql stable set search_path = '' as $f$
  select (pg_catalog.jsonb_build_object('role', 'authenticated', 'aud', 'authenticated')
          || case when p_sub is null then '{}'::jsonb
                  else pg_catalog.jsonb_build_object('sub', p_sub) end
          || case when p_amr is null then '{}'::jsonb
                  else pg_catalog.jsonb_build_object('amr', p_amr) end)::text
$f$;

-- Switches the session to p_login acting as authenticated with p_claims, the
-- way PostgREST (authenticator) and the sync service (thsync) do; or back to
-- the superuser that started the test. No SET clause on purpose: SET LOCAL
-- inside a function with one would be undone when it returns.
create function th988b_test.act_as(p_login text, p_claims text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th988b.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

-- The rows a user holds in every member table, keyed like the
-- delete_my_app_data receipt.
create function th988b_test.counts(p_user uuid)
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

-- Everything a user holds: member rows, identity rows, avatar objects and
-- whether account deletion was started.
create function th988b_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select th988b_test.counts(p_user) || pg_catalog.jsonb_build_object(
    'users', (select count(*) from auth.users where id = p_user),
    'identities', (select count(*) from auth.identities where user_id = p_user),
    'sessions', (select count(*) from auth.sessions where user_id = p_user),
    'avatars', (select count(*) from storage.objects
                where bucket_id = 'avatars' and (storage.foldername(name))[1] = p_user::text),
    'deletion_started', (select account_deletion_started_at is not null
                         from public.profiles where id = p_user))
$f$;

-- A synthetic account with an identity, a session and a row in every member
-- table.
create function th988b_test.seed(p_user uuid)
returns void language plpgsql set search_path = '' as $f$
declare
  hw uuid;
  st uuid;
begin
  insert into auth.users (id, email, aud, role) values
    (p_user, 'synthetic-' || p_user::text || '@example.test', 'authenticated', 'authenticated');
  insert into auth.identities (provider_id, user_id, identity_data, provider) values
    (p_user::text, p_user, pg_catalog.jsonb_build_object('sub', p_user::text), 'email');
  insert into auth.sessions (id, user_id) values (pg_catalog.gen_random_uuid(), p_user);
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

-- A before-delete trigger function that skips the row: an auth.users delete
-- that silently removes nothing.
create function th988b_test.skip_delete()
returns trigger language plpgsql set search_path = '' as $f$
begin
  return null;
end;
$f$;

grant usage on schema th988b_test to public;
grant execute on all functions in schema th988b_test to public;
revoke all on function th988b_test.seed(uuid) from public;

-- Catalogue -------------------------------------------------------------------
select th988b_test.ok(
  (select count(*) from pg_catalog.pg_proc where proname = 'delete_my_account') = 1
  and (select p.prosecdef and p.proconfig = array['search_path=""']
            and p.prorettype = 'pg_catalog.jsonb'::regtype
            and p.proargtypes::text = ('pg_catalog.text'::regtype::oid)::text
            and p.prolang = (select oid from pg_catalog.pg_language where lanname = 'plpgsql')
            and p.proowner = 'postgres'::regrole
       from pg_catalog.pg_proc as p
       where p.oid = 'public.delete_my_account(text)'::regprocedure),
  'delete_my_account: one function, (text) returns jsonb, plpgsql, security definer, empty search_path, owned by postgres');
select th988b_test.ok(
  not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.unnest(p.proargtypes::oid[]) as t(oid)
    where p.oid = 'public.delete_my_account(text)'::regprocedure and t.oid = 'pg_catalog.uuid'::regtype),
  'delete_my_account: takes no uuid argument');
select th988b_test.ok(
  (select string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ','
                     order by a.grantee::regrole::text)
   from pg_catalog.pg_proc as p
   cross join lateral pg_catalog.aclexplode(
     coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
   where p.oid = 'public.delete_my_account(text)'::regprocedure)
  = 'authenticated:EXECUTE,postgres:EXECUTE',
  'delete_my_account: execute is granted to authenticated and held by its owner only; no PUBLIC entry');
create role th988b_plain nologin;
select th988b_test.ok(
  pg_catalog.has_function_privilege('authenticated', 'public.delete_my_account(text)', 'EXECUTE')
  and pg_catalog.has_function_privilege('postgres', 'public.delete_my_account(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('anon', 'public.delete_my_account(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('service_role', 'public.delete_my_account(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('thsync', 'public.delete_my_account(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('th988b_plain', 'public.delete_my_account(text)', 'EXECUTE'),
  'delete_my_account: authenticated and the owner may execute it; anon, service_role, thsync and a role with only PUBLIC may not');

-- Synthetic accounts ------------------------------------------------------------
select th988b_test.seed('00000000-0000-4000-8000-00000988b0a1');
select th988b_test.seed('00000000-0000-4000-8000-00000988b0b1');
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
insert into storage.objects (bucket_id, name) values
  ('avatars', '00000000-0000-4000-8000-00000988b0b1/avatar.png');
select set_config('th988b.a_seeded', th988b_test.state('00000000-0000-4000-8000-00000988b0a1')::text, true);
select set_config('th988b.b_seeded', th988b_test.state('00000000-0000-4000-8000-00000988b0b1')::text, true);
select th988b_test.ok(
  current_setting('th988b.a_seeded')::jsonb = '{"profiles": 1, "quit_plans": 1,
    "program_data": 1, "enrolments": 2, "programme_consents": 3, "account_consents": 1,
    "sync_answers": 1, "sync_lapses": 1, "sync_areas": 1, "sync_accounts": 1,
    "users": 1, "identities": 1, "sessions": 1, "avatars": 0, "deletion_started": false}'::jsonb
  and current_setting('th988b.b_seeded')::jsonb =
      current_setting('th988b.a_seeded')::jsonb || '{"avatars": 1}'::jsonb,
  'setup: synthetic A and B each hold an identity, a session and a row in every member table; B has an avatar object');

-- Who may call it ------------------------------------------------------------------
select th988b_test.act_as(current_setting('th988b.superuser'),
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
set local role anon;
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'permission denied for function delete_my_account', 'anon: delete_my_account is refused');
reset role;
set local role service_role;
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'permission denied for function delete_my_account', 'service_role: delete_my_account is refused');
reset role;
set local role th988b_plain;
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'permission denied for function delete_my_account',
  'a role with only PUBLIC: delete_my_account is refused');
reset role;
-- thsync logged in, not acting as authenticated.
set session authorization thsync;
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'permission denied for function delete_my_account', 'thsync itself: delete_my_account is refused');
select th988b_test.act_as(current_setting('th988b.superuser'), null);

-- Refusals, in the function's order; none deletes anything ------------------------
-- A sync service session acting as A, with a recent sign-in.
select th988b_test.act_as('thsync',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.ok(session_user = 'thsync' and current_user = 'authenticated'
  and auth.uid() = '00000000-0000-4000-8000-00000988b0a1' and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH010', 'The sync service writes only sync tables',
  'A sync: delete_my_account refuses the sync session', 'sync_session_refused');
select th988b_test.act_as('thsync', th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', null));
select th988b_test.refused('select public.delete_my_account(''wrong'')',
  'TH010', 'The sync service writes only sync tables',
  'A sync: the sync refusal comes before the confirmation and sign-in checks', 'sync_session_refused');

-- No caller.
select th988b_test.act_as('authenticator', th988b_test.claims(null, th988b_test.amr_at(30)));
select th988b_test.ok(auth.uid() is null and not public.sync_writer_session(),
  'API session without a subject: auth.uid() is null');
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'Authentication required', 'no caller: delete_my_account is refused');
select th988b_test.act_as('authenticator', null);
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '42501', 'Authentication required', 'no claims at all: delete_my_account is refused');

-- Confirmation.
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.refused('select public.delete_my_account(''delete'')',
  '23514', 'Explicit confirmation required', 'A API: a confirmation other than DELETE is refused');
select th988b_test.refused('select public.delete_my_account(null)',
  '23514', 'Explicit confirmation required', 'A API: a null confirmation is refused');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(3600)));
select th988b_test.refused('select public.delete_my_account('''')',
  '23514', 'Explicit confirmation required',
  'A API: the confirmation check comes before the sign-in check');

-- delete_my_app_data's counts for A, taken in a block that is rolled back.
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
do $reference$
declare
  receipt jsonb;
begin
  begin
    perform public.begin_account_deletion('DELETE');
    receipt := public.delete_my_app_data('DELETE');
    raise exception 'th988b reference rollback';
  exception when raise_exception then
    if sqlerrm <> 'th988b reference rollback' then
      raise;
    end if;
  end;
  perform pg_catalog.set_config('th988b.reference', receipt::text, true);
end;
$reference$;
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  current_setting('th988b.reference')::jsonb = th988b_test.counts('00000000-0000-4000-8000-00000988b0a1')
  and th988b_test.state('00000000-0000-4000-8000-00000988b0a1') = current_setting('th988b.a_seeded')::jsonb,
  'reference: delete_my_app_data returns A''s row counts; the rolled-back block left A unchanged');

-- Deletion not started.
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  '23514', 'Account deletion was not started',
  'A API: before begin_account_deletion, delete_my_account is refused');
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0a1') = current_setting('th988b.a_seeded')::jsonb,
  'A: the refusal before begin_account_deletion deleted nothing; the identity is still present');

-- An avatar object of A is left.
insert into storage.objects (bucket_id, name) values
  ('avatars', '00000000-0000-4000-8000-00000988b0a1/avatar.png');
select set_config('th988b.a_avatar', th988b_test.state('00000000-0000-4000-8000-00000988b0a1')::text, true);
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH016', 'Avatar objects must be removed before the account is deleted',
  'A API: an avatar object left is refused, before the deletion-started check', 'avatar_objects_remain');

-- Recent sign-in. A's avatar is still there, so a token that passes the
-- sign-in check is refused with TH016 next.
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(601)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in 601 s old is refused, before the avatar check', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(86400)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in a day old is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(-61)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in 61 s in the future is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator', th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', null));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a token without amr is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', '[]'::jsonb));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an empty amr is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', '"password"'::jsonb));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr that is not an array is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', '[{"method": "password"}]'::jsonb));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr entry without a timestamp is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', (extract(epoch from now()) - 30)::text))));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr timestamp that is a string is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'timestamp', extract(epoch from now()) - 30))));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr entry without a method is refused', 'recent_authentication_required');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(600)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH016', 'Avatar objects must be removed before the account is deleted',
  'A API: a sign-in exactly 600 s old passes the sign-in check', 'avatar_objects_remain');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(-60)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH016', 'Avatar objects must be removed before the account is deleted',
  'A API: a sign-in 60 s in the future passes the sign-in check', 'avatar_objects_remain');
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1',
    th988b_test.amr_at(86400) || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'otp', 'timestamp', extract(epoch from now()) - 30))));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH016', 'Avatar objects must be removed before the account is deleted',
  'A API: the newest amr entry counts (an old password sign-in and a recent one-time code)',
  'avatar_objects_remain');
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0a1') = current_setting('th988b.a_avatar')::jsonb,
  'A: the avatar and sign-in refusals deleted nothing, the avatar object included');

-- Deletion started, avatar still there.
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.ok(public.begin_account_deletion('DELETE'), 'A API: begin_account_deletion sets the barrier');
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH016', 'Avatar objects must be removed before the account is deleted',
  'A API: after begin_account_deletion an avatar object left is still refused', 'avatar_objects_remain');
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0a1') =
    current_setting('th988b.a_avatar')::jsonb || '{"deletion_started": true}'::jsonb,
  'A: the avatar refusal after begin_account_deletion deleted nothing');

-- A removes the avatar object with its own token (as the Storage API does).
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
delete from storage.objects
where bucket_id = 'avatars' and name = '00000000-0000-4000-8000-00000988b0a1/avatar.png';
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select set_config('th988b.a_ready', th988b_test.state('00000000-0000-4000-8000-00000988b0a1')::text, true);
select th988b_test.ok(
  current_setting('th988b.a_ready')::jsonb =
    current_setting('th988b.a_seeded')::jsonb || '{"deletion_started": true}'::jsonb,
  'A: its avatar object is removed with its own token; everything else is unchanged');

-- The auth.users delete silently removes nothing.
create trigger th988b_skip_delete before delete on auth.users
for each row execute function th988b_test.skip_delete();
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select th988b_test.refused('select public.delete_my_account(''DELETE'')',
  'TH018', 'The account identity was not deleted',
  'A API: an auth.users delete that removes nothing is refused', 'auth_identity_not_deleted');
select th988b_test.act_as(current_setting('th988b.superuser'), null);
drop trigger th988b_skip_delete on auth.users;
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0a1') = current_setting('th988b.a_ready')::jsonb,
  'A: the identity refusal rolled back the app data deletion too (one transaction)');

-- Deletion ----------------------------------------------------------------------
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select set_config('th988b.a_receipt', public.delete_my_account('DELETE')::text, true);
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  current_setting('th988b.a_receipt')::jsonb = current_setting('th988b.reference')::jsonb,
  'A API: delete_my_account returns the same counts as delete_my_app_data for A');
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0a1') = '{"profiles": 0, "quit_plans": 0,
    "program_data": 0, "enrolments": 0, "programme_consents": 0, "account_consents": 0,
    "sync_answers": 0, "sync_lapses": 0, "sync_areas": 0, "sync_accounts": 0,
    "users": 0, "identities": 0, "sessions": 0, "avatars": 0, "deletion_started": null}'::jsonb,
  'A: no row of A is left in any member table, auth.users, auth.identities or auth.sessions');
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0b1') = current_setting('th988b.b_seeded')::jsonb,
  'B: deleting A left every row of B untouched, its identity, session and avatar object included');

-- A repeat with the same token (a retry after a lost response).
select th988b_test.act_as('authenticator',
  th988b_test.claims('00000000-0000-4000-8000-00000988b0a1', th988b_test.amr_at(30)));
select set_config('th988b.a_repeat', public.delete_my_account('DELETE')::text, true);
select th988b_test.act_as(current_setting('th988b.superuser'), null);
select th988b_test.ok(
  current_setting('th988b.a_repeat')::jsonb = '{"profiles": 0, "quit_plans": 0,
    "program_data": 0, "enrolments": 0, "programme_consents": 0, "account_consents": 0,
    "sync_answers": 0, "sync_lapses": 0, "sync_areas": 0, "sync_accounts": 0}'::jsonb,
  'A API: a repeat after the deletion succeeds with zero counts');
select th988b_test.ok(
  th988b_test.state('00000000-0000-4000-8000-00000988b0b1') = current_setting('th988b.b_seeded')::jsonb,
  'B: the repeat left every row of B untouched');

select 'TH988B_SQL_TESTS_COMPLETE' as result;
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

create schema th988b_control;
create function th988b_control.skip_delete()
returns trigger language plpgsql set search_path = '' as $f$
begin
  return null;
end;
$f$;
grant usage on schema th988b_control to public;

-- Synthetic C: deletion started, a recent sign-in, an avatar object left.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000988b0c1', 'synthetic-control-c1@example.test',
   'authenticated', 'authenticated');
update public.profiles set account_deletion_started_at = now()
where id = '00000000-0000-4000-8000-00000988b0c1';
insert into storage.objects (bucket_id, name) values
  ('avatars', '00000000-0000-4000-8000-00000988b0c1/avatar.png');
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000988b0c1', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);

-- Each call runs in its own block; the outcome is "completed" or the SQLSTATE
-- that refused it.
-- 1. With the avatar object left.
set local role authenticated;
do $avatar$
declare
  outcome text;
begin
  begin
    perform public.delete_my_account('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988bc.avatar_left', outcome, true);
  raise notice 'CONTROL delete_my_account with an avatar object left: %', outcome;
end;
$avatar$;
reset role;

-- 2. Avatar object removed; every delete of an auth.users row now removes
-- nothing.
delete from storage.objects
where bucket_id = 'avatars' and name = '00000000-0000-4000-8000-00000988b0c1/avatar.png';
create trigger th988b_control_skip_delete before delete on auth.users
for each row execute function th988b_control.skip_delete();
set local role authenticated;
do $silent$
declare
  outcome text;
begin
  begin
    perform public.delete_my_account('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988bc.silent_delete', outcome, true);
  raise notice 'CONTROL delete_my_account when the auth.users delete removes nothing: %', outcome;
end;
$silent$;
reset role;
select set_config('th988bc.identity',
  (select count(*) from auth.users where id = '00000000-0000-4000-8000-00000988b0c1')::text, true);
do $report$
begin
  raise notice 'CONTROL auth.users rows of C left: %', pg_catalog.current_setting('th988bc.identity');
end;
$report$;

select case
  when current_setting('th988bc.avatar_left') = 'TH016'
   and current_setting('th988bc.silent_delete') = 'TH018'
   and current_setting('th988bc.identity') = '1'
    then 'TH988B_CONTROL_REFUSED_TH016_TH018'
  when current_setting('th988bc.avatar_left') = '42883'
   and current_setting('th988bc.silent_delete') = '42883'
    then 'TH988B_CONTROL_FUNCTION_ABSENT'
  when current_setting('th988bc.avatar_left') = 'completed'
    then 'TH988B_CONTROL_STORAGE_CHECK_MISSING'
  when current_setting('th988bc.silent_delete') = 'completed'
    then 'TH988B_CONTROL_RECHECK_MISSING'
  else 'TH988B_CONTROL_UNEXPECTED'
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
  echo "Account identity deletion check failed: $1" >&2
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

# The SQL on stdin as one statement per line: comments removed, lower case,
# double quotes dropped, whitespace collapsed to single spaces, split at ";".
statements() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' |
    sed -E 's/ +/ /g' | tr ';' '\n' | sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}

# One definition, in this migration ------------------------------------------------
defined_in=$(grep -Eil '^create (or replace )?function +("?public"?\.)?"?delete_my_account"? *\(' "${migration_files[@]}" || true)
[[ "$defined_in" == "$migration" ]] ||
  fail "public.delete_my_account must be defined in $migration only (found in: ${defined_in:-nothing})"
[[ "$(grep -Eic '^create (or replace )?function +("?public"?\.)?"?delete_my_account"? *\(' "$migration")" -eq 1 ]] ||
  fail 'public.delete_my_account must be defined exactly once'

# The migration, with the function body replaced by "body": exactly these
# statements. Nothing else is created, replaced, altered, dropped or granted
# (no policy, trigger, owner change, or change in auth or storage).
body=$(sed -n '/^create function public\.delete_my_account(p_confirmation text)$/,/^\$\$;$/p' "$migration")
[[ -n "$body" ]] || fail 'the function must start with "create function public.delete_my_account(p_confirmation text)" and end with "$$;"'
outline=$(awk '
  /^as \$\$$/ { print "as body"; skip = 1; next }
  skip && /^\$\$;$/ { print ";"; skip = 0; next }
  !skip { print }
' "$migration" | statements)
expected_outline="begin
create function public.delete_my_account(p_confirmation text) returns jsonb language plpgsql security definer set search_path = '' as body
revoke all on function public.delete_my_account(text) from public, anon, authenticated, service_role
grant execute on function public.delete_my_account(text) to authenticated
commit"
[[ "$outline" == "$expected_outline" ]] ||
  fail "$migration must contain exactly: the function (security definer, search_path '', no uuid parameter), the revoke from public, anon, authenticated and service_role, and the grant to authenticated. Got:
$outline"

# No other migration grants or revokes anything on it.
all_statements=$(cat "${migration_files[@]}" | statements)
grants=$(grep -E '(^| )(grant|revoke) ' <<<"$all_statements" | grep -E 'delete_my_account' || true)
[[ "$grants" == "revoke all on function public.delete_my_account(text) from public, anon, authenticated, service_role
grant execute on function public.delete_my_account(text) to authenticated" ]] ||
  fail "the only privileges on delete_my_account are the revoke and the grant to authenticated in $migration; found:
$grants"

# Body order -------------------------------------------------------------------
# Line number (within the body, comments removed) of the one line matching the
# extended regex $1; fails when it is missing or appears more than once.
# shellcheck disable=SC2001  # per-line comment removal, not one substitution
code=$(sed 's/--.*$//' <<<"$body")
line_of() {
  local found count
  found=$(grep -nE -- "$1" <<<"$code" || true)
  count=$(grep -c . <<<"$found" || true)
  [[ "$count" -eq 1 ]] || fail "delete_my_account must contain exactly one line matching /$1/ (found $count)"
  echo "${found%%:*}"
}
next_line_matches() {
  local at="$1" pattern="$2" what="$3"
  sed -n "$((at + 1))p" <<<"$code" | grep -Eq -- "$pattern" || fail "delete_my_account: $what"
}
l_caller=$(line_of "^  caller_id uuid := auth\\.uid\\(\\);$")
l_null=$(line_of "^  if caller_id is null then$")
next_line_matches "$l_null" "^    raise insufficient_privilege using message = 'Authentication required';$" \
  'no caller must raise insufficient_privilege (42501)'
l_sync=$(line_of "^  if public\\.sync_writer_session\\(\\) then$")
next_line_matches "$l_sync" "^    raise exception using errcode = 'TH010',$" 'a sync session must raise TH010'
l_confirm=$(line_of "^  if p_confirmation is distinct from 'DELETE' then$")
next_line_matches "$l_confirm" "^    raise check_violation using message = 'Explicit confirmation required';$" \
  'a wrong confirmation must raise check_violation (23514)'
l_amr=$(line_of "auth\\.jwt\\(\\) -> 'amr'\\) = 'array'$")
l_age=$(line_of "^  if sign_in_age is null or sign_in_age > 600 or sign_in_age < -60 then$")
next_line_matches "$l_age" "^    raise exception using errcode = 'TH017',$" 'a sign-in that is not recent must raise TH017'
l_storage=$(line_of "^    from storage\\.objects$")
line_of "^    where bucket_id = 'avatars'$" >/dev/null
line_of "^      and \\(storage\\.foldername\\(name\\)\\)\\[1\\] = caller_id::text$" >/dev/null
l_th016=$(line_of "errcode = 'TH016',$")
l_app=$(line_of "^  counts := public\\.delete_my_app_data\\(p_confirmation\\);$")
l_delete=$(line_of "^  delete from auth\\.users where id = caller_id;$")
l_recheck=$(line_of "^  if exists \\(select 1 from auth\\.users where id = caller_id\\) then$")
next_line_matches "$l_recheck" "^    raise exception using errcode = 'TH018',$" \
  'the auth.users row still present after the delete must raise TH018'
l_return=$(line_of "^  return counts;$")
order=("$l_caller" "$l_null" "$l_sync" "$l_confirm" "$l_amr" "$l_age" "$l_storage" "$l_th016" \
  "$l_app" "$l_delete" "$l_recheck" "$l_return")
for ((i = 1; i < ${#order[@]}; i++)); do
  ((order[i - 1] < order[i])) ||
    fail 'delete_my_account must run: caller, sync refusal (TH010), confirmation, recent sign-in (TH017), avatar check (TH016), delete_my_app_data, delete from auth.users, re-check (TH018), return'
done
# Nothing is deleted, and delete_my_app_data is not called, before the sync
# refusal and the other checks; the only delete is the auth.users row.
first_delete=$(grep -nE '(^|[^a-z_])(delete|truncate|update|insert)([^a-z_]|$)|delete_my_app_data' <<<"$code" |
  head -n 1 | cut -d: -f1)
[[ "$first_delete" == "$l_app" ]] ||
  fail 'delete_my_account must not write or call delete_my_app_data before its checks'
[[ "$(grep -cE '(^|[^a-z_])delete +from' <<<"$code")" -eq 1 ]] ||
  fail 'the only delete in delete_my_account is the caller'"'"'s auth.users row'
if grep -Eiq '(^|[^a-z_])(execute|set +role|set +session|insert|update|truncate)([^a-z_]|$)|request\.jwt|storage\.objects.*delete' <<<"$code"; then
  fail 'delete_my_account runs no dynamic SQL, changes no role, writes nothing but the delete, and reads the caller only through auth.uid() and auth.jwt()'
fi
# The registered messages, as raised.
grep -Fq "message = 'Avatar objects must be removed before the account is deleted'," <<<"$code" ||
  fail 'TH016 message changed'
grep -Fq "message = 'Recent authentication is required'," <<<"$code" || fail 'TH017 message changed'
grep -Fq "message = 'The account identity was not deleted'," <<<"$code" || fail 'TH018 message changed'

# No migration deletes storage rows; only delete_my_account deletes auth.users
# rows ------------------------------------------------------------------------------
if grep -Eq '(^|[^a-z_])delete from (only )?storage\.' <<<"$all_statements"; then
  fail 'no migration may delete from a storage table (files would be left in the storage backend)'
fi
auth_deletes=$(grep -Eo '(^|[^a-z_])delete from (only )?auth\.users[^;]*' <<<"$all_statements" | sed -E 's/^ //' || true)
[[ "$auth_deletes" == 'delete from auth.users where id = caller_id' ]] ||
  fail "the only auth.users delete in the migrations is delete_my_account's, for the caller; found:
$auth_deletes"

# Registry and contract -----------------------------------------------------------
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
for row in 'TH016|avatar_objects_remain|Avatar objects must be removed before the account is deleted' \
  'TH017|recent_authentication_required|Recent authentication is required' \
  'TH018|auth_identity_not_deleted|The account identity was not deleted'; do
  IFS='|' read -r c name message <<<"$row"
  line=$(grep -E "^\\| \`$c\` \\| \`$name\` \\|" "$contract" || true)
  [[ -n "$line" ]] || fail "$c $name is not in the registry in $contract"
  grep -Fq '`delete_my_account`' <<<"$line" || fail "the $c registry row must name delete_my_account"
  grep -Fq "| $message |" <<<"$line" || fail "the $c registry row must carry its message"
done
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_account_identity_deletion.sh`' "$contract" ||
  fail "$contract must name this check"
deletion_section=$(sed -n '/^## Account-data deletion$/,/^## /p' "$contract" | tr '\n' ' ' | sed -E 's/ +/ /g')
# shellcheck disable=SC2016
grep -Fq '`delete_my_account('"'"'DELETE'"'"')`' <<<"$deletion_section" ||
  fail 'the account-data deletion section must describe delete_my_account'
grep -Fq 'never deletes storage rows' <<<"$deletion_section" ||
  fail 'the account-data deletion section must say the function never deletes storage rows'

echo 'Account identity deletion static checks passed.'

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
  echo "$out" | grep -q 'TH988B_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH988B_CONTROL_REFUSED_TH016_TH018' ||
    fail 'control: an avatar object left or an identity left after the delete was not refused'
  echo 'Account identity deletion SQL test and control passed.'
fi
