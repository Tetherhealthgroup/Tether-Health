#!/usr/bin/env bash
# Checks that public.begin_account_deletion requires a recent sign-in. After
# its existing refusals (no caller, 42501; a sync service session, TH009; a
# confirmation other than DELETE, 23514) and before it sets
# profiles.account_deletion_started_at, it refuses a token whose newest amr
# entry is older than 600 seconds, more than 60 seconds in the future, or
# missing or malformed (TH017), with the same check as delete_my_account.
# Its signature, security definer, empty search_path, owner and privileges
# are unchanged, and so is the rest of its body.
#
#   bash supabase/tests/verify_begin_deletion_recent_sign_in.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator and creates a test role, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: for one
#       synthetic account it calls begin_account_deletion with a token signed
#       in an hour ago, and for another with a token signed in 30 seconds ago,
#       and reports:
#         TH988E_CONTROL_STALE_SIGN_IN_REFUSED  (expected with the migration:
#             the stale token is refused with TH017 and sets nothing; the
#             recent one starts deletion)
#         TH988E_CONTROL_STALE_SIGN_IN_STARTED  (a tree without the migration:
#             the stale token starts deletion)
#         TH988E_CONTROL_UNEXPECTED             (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180009_begin_deletion_recent_sign_in.sql"
previous="supabase/migrations/202610180002_service_session_guard.sql"
reference="supabase/migrations/202610180008_delete_my_account.sql"
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
  if pg_catalog.to_regprocedure('auth.jwt()') is null or pg_catalog.to_regclass('storage.objects') is null then
    raise exception 'FAIL setup: auth.jwt() and storage.objects are needed';
  end if;
end;
$setup$;

select set_config('th988e.superuser', session_user, true);

create schema th988e_test;

create function th988e_test.ok(p_cond boolean, p_label text)
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
create function th988e_test.refused(
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
create function th988e_test.amr_at(p_age numeric)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - p_age))
$f$;

-- Token claims for p_sub; a null p_sub or p_amr leaves that claim out.
create function th988e_test.claims(p_sub text, p_amr jsonb)
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
create function th988e_test.act_as(p_login text, p_claims text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th988e.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

-- What a user holds: identity, profile, deletion barrier, member rows and
-- avatar objects.
create function th988e_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'users', (select count(*) from auth.users where id = p_user),
    'profiles', (select count(*) from public.profiles where id = p_user),
    'deletion_started_at', (select account_deletion_started_at from public.profiles where id = p_user),
    'quit_plans', (select count(*) from public.quit_plans where user_id = p_user),
    'program_data', (select count(*) from public.program_data where user_id = p_user),
    'avatars', (select count(*) from storage.objects
                where bucket_id = 'avatars' and (storage.foldername(name))[1] = p_user::text))
$f$;

-- A synthetic account: an identity (its profile is created by trigger), a
-- quit plan and program data.
create function th988e_test.seed(p_user uuid)
returns void language plpgsql set search_path = '' as $f$
begin
  insert into auth.users (id, email, aud, role) values
    (p_user, 'synthetic-' || p_user::text || '@example.test', 'authenticated', 'authenticated');
  insert into public.quit_plans (user_id, quit_date) values (p_user, current_date);
  insert into public.program_data (user_id, program_id, payload) values (p_user, 'heartwise', '{}');
end;
$f$;

-- Counts every update of a profile row. A sequence is not rolled back, so a
-- refused call whose barrier update was undone by the error still shows.
create sequence th988e_test.profile_updates;
create function th988e_test.note_profile_update()
returns trigger language plpgsql set search_path = '' as $f$
begin
  perform pg_catalog.nextval('th988e_test.profile_updates');
  return new;
end;
$f$;

grant usage on schema th988e_test to public;
grant execute on all functions in schema th988e_test to public;
grant usage on sequence th988e_test.profile_updates to public;
revoke all on function th988e_test.seed(uuid) from public;

-- Catalogue -------------------------------------------------------------------
select th988e_test.ok(
  (select count(*) from pg_catalog.pg_proc where proname = 'begin_account_deletion') = 1
  and (select p.prosecdef and p.proconfig = array['search_path=""']
            and p.prorettype = 'pg_catalog.bool'::regtype
            and p.proargtypes::text = ('pg_catalog.text'::regtype::oid)::text
            and p.prolang = (select oid from pg_catalog.pg_language where lanname = 'plpgsql')
            and p.proowner = (select proowner from pg_catalog.pg_proc
                              where oid = 'public.delete_my_app_data(text)'::regprocedure)
       from pg_catalog.pg_proc as p
       where p.oid = 'public.begin_account_deletion(text)'::regprocedure),
  'begin_account_deletion: one function, (text) returns boolean, plpgsql, security definer, empty search_path, same owner as delete_my_app_data');
select th988e_test.ok(
  (select string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ','
                     order by a.grantee::regrole::text)
   from pg_catalog.pg_proc as p
   cross join lateral pg_catalog.aclexplode(
     coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
   where p.oid = 'public.begin_account_deletion(text)'::regprocedure)
  = 'authenticated:EXECUTE,' || (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
                                 where oid = 'public.begin_account_deletion(text)'::regprocedure) || ':EXECUTE',
  'begin_account_deletion: execute is granted to authenticated and held by its owner only; no PUBLIC entry');
create role th988e_plain nologin;
select th988e_test.ok(
  pg_catalog.has_function_privilege('authenticated', 'public.begin_account_deletion(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('anon', 'public.begin_account_deletion(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('service_role', 'public.begin_account_deletion(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('thsync', 'public.begin_account_deletion(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('th988e_plain', 'public.begin_account_deletion(text)', 'EXECUTE'),
  'begin_account_deletion: authenticated may execute it; anon, service_role, thsync and a role with only PUBLIC may not');

-- Synthetic accounts ------------------------------------------------------------
select th988e_test.seed('00000000-0000-4000-8000-00000988e0a1');
select th988e_test.seed('00000000-0000-4000-8000-00000988e0b1');
select th988e_test.seed('00000000-0000-4000-8000-00000988e0c1');
select th988e_test.seed('00000000-0000-4000-8000-00000988e0d1');
select th988e_test.seed('00000000-0000-4000-8000-00000988e0f1');
select set_config('th988e.seeded', th988e_test.state('00000000-0000-4000-8000-00000988e0a1')::text, true);
select th988e_test.ok(
  current_setting('th988e.seeded')::jsonb = '{"users": 1, "profiles": 1, "deletion_started_at": null,
    "quit_plans": 1, "program_data": 1, "avatars": 0}'::jsonb
  and th988e_test.state('00000000-0000-4000-8000-00000988e0b1') = current_setting('th988e.seeded')::jsonb
  and th988e_test.state('00000000-0000-4000-8000-00000988e0c1') = current_setting('th988e.seeded')::jsonb
  and th988e_test.state('00000000-0000-4000-8000-00000988e0d1') = current_setting('th988e.seeded')::jsonb
  and th988e_test.state('00000000-0000-4000-8000-00000988e0f1') = current_setting('th988e.seeded')::jsonb,
  'setup: synthetic A, B, C, D and F each hold an identity, a profile without a deletion barrier, a quit plan and program data');

-- Who may call it ------------------------------------------------------------------
select th988e_test.act_as(current_setting('th988e.superuser'),
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(30)));
set local role anon;
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'permission denied for function begin_account_deletion', 'anon: begin_account_deletion is refused');
reset role;
set local role service_role;
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'permission denied for function begin_account_deletion', 'service_role: begin_account_deletion is refused');
reset role;
set local role th988e_plain;
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'permission denied for function begin_account_deletion',
  'a role with only PUBLIC: begin_account_deletion is refused');
reset role;
-- thsync logged in, not acting as authenticated.
set session authorization thsync;
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'permission denied for function begin_account_deletion', 'thsync itself: begin_account_deletion is refused');
select th988e_test.act_as(current_setting('th988e.superuser'), null);

create trigger th988e_note_profile_update before update on public.profiles
for each row execute function th988e_test.note_profile_update();

-- Earlier refusals keep their codes and come before the sign-in check ---------------
-- A sync service session acting as A: refused with TH009 whatever the sign-in.
select th988e_test.act_as('thsync',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(30)));
select th988e_test.ok(session_user = 'thsync' and current_user = 'authenticated'
  and auth.uid() = '00000000-0000-4000-8000-00000988e0a1' and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH009', 'Account deletion goes through the API',
  'A sync, recent sign-in: begin_account_deletion refuses the sync session as before', 'deletion_via_api_only');
select th988e_test.act_as('thsync',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(3600)));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH009', 'Account deletion goes through the API',
  'A sync, stale sign-in: the sync refusal comes before the sign-in check', 'deletion_via_api_only');
select th988e_test.act_as('thsync', th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', null));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH009', 'Account deletion goes through the API',
  'A sync, no amr: the sync refusal comes before the sign-in check', 'deletion_via_api_only');

-- No caller.
select th988e_test.act_as('authenticator', th988e_test.claims(null, th988e_test.amr_at(3600)));
select th988e_test.ok(auth.uid() is null and not public.sync_writer_session(),
  'API session without a subject: auth.uid() is null');
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'Authentication required', 'no caller, stale sign-in: refused as before (42501), before the sign-in check');
select th988e_test.act_as('authenticator', null);
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  '42501', 'Authentication required', 'no claims at all: refused as before (42501)');

-- Confirmation.
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(30)));
select th988e_test.refused('select public.begin_account_deletion(''delete'')',
  '23514', 'Explicit confirmation required', 'A API: a confirmation other than DELETE is refused as before');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(3600)));
select th988e_test.refused('select public.begin_account_deletion(null)',
  '23514', 'Explicit confirmation required',
  'A API: the confirmation check comes before the sign-in check');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  th988e_test.state('00000000-0000-4000-8000-00000988e0a1') = current_setting('th988e.seeded')::jsonb,
  'A: the earlier refusals set nothing');

-- Sign-in that is not recent: TH017, nothing set ------------------------------------
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(601)));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in 601 s old is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(3600)));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in an hour old (a token near its expiry) is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(-61)));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a sign-in 61 s in the future is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator', th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', null));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: a token without amr is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', '[]'::jsonb));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an empty amr is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', '"password"'::jsonb));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr that is not an array is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', '["password"]'::jsonb));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr entry that is not an object is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', '[{"method": "password"}]'::jsonb));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr entry without a timestamp is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', (extract(epoch from now()) - 30)::text))));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr timestamp that is a string is refused', 'recent_authentication_required');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'timestamp', extract(epoch from now()) - 30))));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'A API: an amr entry without a method is refused', 'recent_authentication_required');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  th988e_test.state('00000000-0000-4000-8000-00000988e0a1') = current_setting('th988e.seeded')::jsonb,
  'A: the sign-in refusals set no deletion barrier and changed nothing');
select th988e_test.ok(
  (select not is_called from th988e_test.profile_updates),
  'A: every refusal came before the barrier update (no profile update ran, not even one undone by the error)');

-- With no barrier set, A may still upload an avatar with its own token.
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0a1', th988e_test.amr_at(3600)));
insert into storage.objects (bucket_id, name) values
  ('avatars', '00000000-0000-4000-8000-00000988e0a1/avatar.png');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  th988e_test.state('00000000-0000-4000-8000-00000988e0a1') =
    current_setting('th988e.seeded')::jsonb || '{"avatars": 1}'::jsonb,
  'A API: after the sign-in refusals A can still upload an avatar (no barrier was set)');

-- Boundaries: 600 s old and 60 s in the future pass ----------------------------------
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0b1', th988e_test.amr_at(600)));
select th988e_test.ok(public.begin_account_deletion('DELETE'),
  'B API: a sign-in exactly 600 s old starts deletion');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0c1', th988e_test.amr_at(-60)));
select th988e_test.ok(public.begin_account_deletion('DELETE'),
  'C API: a sign-in 60 s in the future starts deletion');
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0d1',
    th988e_test.amr_at(86400) || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'otp', 'timestamp', extract(epoch from now()) - 30))));
select th988e_test.ok(public.begin_account_deletion('DELETE'),
  'D API: the newest amr entry counts (an old password sign-in and a recent one-time code)');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  (select bool_and(account_deletion_started_at = now()) and count(*) = 3 from public.profiles
   where id in ('00000000-0000-4000-8000-00000988e0b1', '00000000-0000-4000-8000-00000988e0c1',
                '00000000-0000-4000-8000-00000988e0d1')),
  'B, C, D: the deletion barrier is set to the transaction time, as before');

-- A recent sign-in starts deletion exactly as before ----------------------------------
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0f1', th988e_test.amr_at(30)));
select th988e_test.ok(public.begin_account_deletion('DELETE'),
  'F API: a sign-in 30 s old starts deletion (returns true)');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select set_config('th988e.f_started', th988e_test.state('00000000-0000-4000-8000-00000988e0f1')::text, true);
select th988e_test.ok(
  current_setting('th988e.f_started')::jsonb =
    current_setting('th988e.seeded')::jsonb
    || pg_catalog.jsonb_build_object('deletion_started_at', now()),
  'F: the deletion barrier is set; nothing else changed');
-- The barrier blocks avatar uploads, as before.
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0f1', th988e_test.amr_at(30)));
select th988e_test.refused(
  'insert into storage.objects (bucket_id, name) values (''avatars'', ''00000000-0000-4000-8000-00000988e0f1/avatar.png'')',
  '42501', 'new row violates row-level security policy%',
  'F API: after begin_account_deletion an avatar upload is refused, as before');
-- Repeat calls: a recent token returns true and keeps the barrier; a stale
-- token is refused and keeps it too.
select th988e_test.ok(public.begin_account_deletion('DELETE'),
  'F API: a repeat with a recent sign-in returns true, as before');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select set_config('th988e.updates', (select last_value from th988e_test.profile_updates)::text, true);
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0f1', th988e_test.amr_at(601)));
select th988e_test.refused('select public.begin_account_deletion(''DELETE'')',
  'TH017', 'Recent authentication is required',
  'F API: a repeat with a stale sign-in is refused', 'recent_authentication_required');
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  th988e_test.state('00000000-0000-4000-8000-00000988e0f1') = current_setting('th988e.f_started')::jsonb
  and (select last_value from th988e_test.profile_updates)::text = current_setting('th988e.updates'),
  'F: the repeats left the barrier and every row unchanged; the stale repeat ran no profile update');
drop trigger th988e_note_profile_update on public.profiles;

-- The rest of the deletion still works with a recent sign-in --------------------------
select th988e_test.act_as('authenticator',
  th988e_test.claims('00000000-0000-4000-8000-00000988e0f1', th988e_test.amr_at(30)));
select set_config('th988e.f_receipt', public.delete_my_account('DELETE')::text, true);
select th988e_test.act_as(current_setting('th988e.superuser'), null);
select th988e_test.ok(
  (current_setting('th988e.f_receipt')::jsonb ->> 'profiles') = '1'
  and (current_setting('th988e.f_receipt')::jsonb ->> 'quit_plans') = '1'
  and (current_setting('th988e.f_receipt')::jsonb ->> 'program_data') = '1'
  and th988e_test.state('00000000-0000-4000-8000-00000988e0f1') = '{"users": 0, "profiles": 0,
    "deletion_started_at": null, "quit_plans": 0, "program_data": 0, "avatars": 0}'::jsonb,
  'F API: after begin_account_deletion, delete_my_account deletes F''s rows and identity');
select th988e_test.ok(
  th988e_test.state('00000000-0000-4000-8000-00000988e0a1') =
    current_setting('th988e.seeded')::jsonb || '{"avatars": 1}'::jsonb,
  'A: untouched by the other accounts'' deletion');

select 'TH988E_SQL_TESTS_COMPLETE' as result;
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

create schema th988e_control;

-- Synthetic G (signed in an hour ago) and H (signed in 30 seconds ago).
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000988e0e1', 'synthetic-control-g1@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-00000988e0e2', 'synthetic-control-h1@example.test', 'authenticated', 'authenticated');

-- Each call runs in its own block; the outcome is "completed" or the SQLSTATE
-- that refused it.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000988e0e1', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 3600)))::text, true);
set local role authenticated;
do $stale$
declare
  outcome text;
begin
  begin
    perform public.begin_account_deletion('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988ec.stale', outcome, true);
  raise notice 'CONTROL begin_account_deletion with a sign-in an hour old: %', outcome;
end;
$stale$;
reset role;

select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000988e0e2', 'role', 'authenticated',
  'amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);
set local role authenticated;
do $recent$
declare
  outcome text;
begin
  begin
    perform public.begin_account_deletion('DELETE');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th988ec.recent', outcome, true);
  raise notice 'CONTROL begin_account_deletion with a sign-in 30 s old: %', outcome;
end;
$recent$;
reset role;

select set_config('th988ec.stale_barrier', (select (account_deletion_started_at is not null)::text
  from public.profiles where id = '00000000-0000-4000-8000-00000988e0e1'), true);
select set_config('th988ec.recent_barrier', (select (account_deletion_started_at is not null)::text
  from public.profiles where id = '00000000-0000-4000-8000-00000988e0e2'), true);
do $report$
begin
  raise notice 'CONTROL deletion barrier set: stale sign-in %, recent sign-in %',
    pg_catalog.current_setting('th988ec.stale_barrier'), pg_catalog.current_setting('th988ec.recent_barrier');
end;
$report$;

select case
  when current_setting('th988ec.stale') = 'TH017'
   and current_setting('th988ec.stale_barrier') = 'false'
   and current_setting('th988ec.recent') = 'completed'
   and current_setting('th988ec.recent_barrier') = 'true'
    then 'TH988E_CONTROL_STALE_SIGN_IN_REFUSED'
  when current_setting('th988ec.stale') = 'completed'
   and current_setting('th988ec.stale_barrier') = 'true'
   and current_setting('th988ec.recent') = 'completed'
   and current_setting('th988ec.recent_barrier') = 'true'
    then 'TH988E_CONTROL_STALE_SIGN_IN_STARTED'
  else 'TH988E_CONTROL_UNEXPECTED'
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
  echo "Begin-deletion recent sign-in check failed: $1" >&2
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

for f in "$migration" "$previous" "$reference" "$contract"; do
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

# The SQL on stdin as one statement per line: comments removed, lower case,
# double quotes dropped, whitespace collapsed to single spaces, split at ";".
statements() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' |
    sed -E 's/ +/ /g' | tr ';' '\n' | sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}

# The latest definition is this migration's, defined once ---------------------------
defining='^create (or replace )?function +("?public"?\.)?"?begin_account_deletion"? *\('
latest=$(grep -Eil "$defining" "${migration_files[@]}" | tail -n 1 || true)
[[ "$latest" == "$migration" ]] ||
  fail "the latest definition of public.begin_account_deletion must be in $migration (found: ${latest:-nothing})"
[[ "$(grep -Eic "$defining" "$migration")" -eq 1 ]] ||
  fail 'public.begin_account_deletion must be defined exactly once in the migration'

# The migration, with the function body replaced by "body": exactly these
# statements. Nothing else is created, replaced, altered, dropped, granted or
# revoked (no owner or privilege change, no other function).
outline=$(awk '
  /^as \$\$$/ { print "as body"; skip = 1; next }
  skip && /^\$\$;$/ { print ";"; skip = 0; next }
  !skip { print }
' "$migration" | statements)
expected_outline="begin
create or replace function public.begin_account_deletion(p_confirmation text) returns boolean language plpgsql security definer set search_path = '' as body
commit"
[[ "$outline" == "$expected_outline" ]] ||
  fail "$migration must contain exactly the create or replace of begin_account_deletion (same signature, security definer, search_path ''), and nothing else. Got:
$outline"

# Privileges on it are still only the earlier revokes and grants.
all_statements=$(cat "${migration_files[@]}" | statements)
grants=$(grep -E '(^| )(grant|revoke) ' <<<"$all_statements" | grep -E 'begin_account_deletion' || true)
[[ "$grants" == "revoke all on function public.begin_account_deletion(text) from public, anon, authenticated
grant execute on function public.begin_account_deletion(text) to authenticated
revoke all on function public.begin_account_deletion(text) from public, anon, authenticated
grant execute on function public.begin_account_deletion(text) to authenticated" ]] ||
  fail "the privileges on begin_account_deletion must be unchanged (the earlier revokes and grants to authenticated only); found:
$grants"

# The body ---------------------------------------------------------------------
body_of() {
  sed -n "/^create \\(or replace \\)\\{0,1\\}function public\\.$1(p_confirmation text)$/,/^\\\$\\\$;$/p" "$2"
}
body=$(body_of begin_account_deletion "$migration")
previous_body=$(body_of begin_account_deletion "$previous")
reference_body=$(body_of delete_my_account "$reference")
[[ -n "$body" && -n "$previous_body" && -n "$reference_body" ]] ||
  fail 'could not read the begin_account_deletion and delete_my_account definitions'

# The recent sign-in check: from the comment that opens it to the end if
# after its TH017 raise.
sign_in_block() {
  awk '
    /^  -- Recent sign-in: the newest amr entry/ { on = 1; n++ }
    on { print }
    on && /^  end if;$/ { on = 0 }
  ' <<<"$1"
}
block=$(sign_in_block "$body")
reference_block=$(sign_in_block "$reference_body")
[[ -n "$reference_block" ]] || fail "no recent sign-in check found in $reference"
[[ "$(grep -c '^  -- Recent sign-in: the newest amr entry' <<<"$body")" -eq 1 ]] ||
  fail 'begin_account_deletion must contain the recent sign-in check exactly once'
[[ "$block" == "$reference_block" ]] ||
  fail "the recent sign-in check in begin_account_deletion must be identical to delete_my_account's"
for want in "raise exception using errcode = 'TH017'," "message = 'Recent authentication is required'," \
  "hint = 'recent_authentication_required';"; do
  grep -Fq "$want" <<<"$block" || fail 'the recent sign-in check must raise TH017 with its registered message and hint'
done
[[ "$(grep -c "TH017" <<<"$body")" -eq 1 ]] || fail 'begin_account_deletion raises TH017 in one place only'

# Placement: as in delete_my_account, the check directly follows the
# confirmation check (same lines, from the confirmation check to the end of the
# sign-in check), and precedes the barrier update.
from_confirmation() {
  awk '
    /^  if p_confirmation is distinct from .DELETE. then$/ { on = 1 }
    on { print }
    on && /^      hint = .recent_authentication_required.;$/ { getline; print; exit }
  ' <<<"$1"
}
[[ "$(from_confirmation "$body")" == "$(from_confirmation "$reference_body")" ]] ||
  fail 'the recent sign-in check must directly follow the confirmation check, as in delete_my_account'
# shellcheck disable=SC2001  # per-line comment removal, not one substitution
code=$(sed 's/--.*$//' <<<"$body")
line_of() {
  local found count
  found=$(grep -nE -- "$1" <<<"$code" || true)
  count=$(grep -c . <<<"$found" || true)
  [[ "$count" -eq 1 ]] || fail "begin_account_deletion must contain exactly one line matching /$1/ (found $count)"
  echo "${found%%:*}"
}
next_line_matches() {
  grep -Eq -- "$2" <<<"$(sed -n "$(($1 + 1))p" <<<"$code")" || fail "begin_account_deletion: $3"
}
l_caller=$(line_of "^  caller_id uuid := auth\\.uid\\(\\);$")
line_of "^  newest_sign_in numeric;$" >/dev/null
line_of "^  sign_in_age numeric;$" >/dev/null
l_null=$(line_of "^  if caller_id is null then$")
next_line_matches "$l_null" "^    raise insufficient_privilege using message = 'Authentication required';$" \
  'no caller must still raise insufficient_privilege (42501)'
l_sync=$(line_of "^  if public\\.sync_writer_session\\(\\) then$")
next_line_matches "$l_sync" "^    raise exception using errcode = 'TH009',$" 'a sync session must still raise TH009'
l_confirm=$(line_of "^  if p_confirmation is distinct from 'DELETE' then$")
l_amr=$(line_of "auth\\.jwt\\(\\) -> 'amr'\\) = 'array'$")
l_age=$(line_of "^  if sign_in_age is null or sign_in_age > 600 or sign_in_age < -60 then$")
l_th017=$(line_of "errcode = 'TH017',$")
l_update=$(line_of "^  update public\\.profiles$")
line_of "^  set account_deletion_started_at = coalesce\\(account_deletion_started_at, now\\(\\)\\)$" >/dev/null
l_return=$(line_of "^  return true;$")
order=("$l_caller" "$l_null" "$l_sync" "$l_confirm" "$l_amr" "$l_age" "$l_th017" "$l_update" "$l_return")
for ((i = 1; i < ${#order[@]}; i++)); do
  ((order[i - 1] < order[i])) ||
    fail 'begin_account_deletion must run: caller, sync refusal (TH009), confirmation, recent sign-in (TH017), barrier update, return'
done
# The only write is the barrier update, after every check.
first_write=$(grep -nE '(^|[^a-z_])(delete|truncate|update|insert)([^a-z_]|$)' <<<"$code" | head -n 1 | cut -d: -f1)
[[ "$first_write" == "$l_update" ]] || fail 'begin_account_deletion must not write before its checks'
[[ "$(grep -cE '(^|[^a-z_])(delete|truncate|update|insert)([^a-z_]|$)' <<<"$code")" -eq 1 ]] ||
  fail 'the only write in begin_account_deletion is the barrier update'
if grep -Eiq '(^|[^a-z_])(execute|set +role|set +session)([^a-z_]|$)|request\.jwt' <<<"$code"; then
  fail 'begin_account_deletion runs no dynamic SQL, changes no role, and reads the token only through auth.uid() and auth.jwt()'
fi
# Everything else is the previous body, unchanged.
without_check=$(awk '
  /^  newest_sign_in numeric;$/ || /^  sign_in_age numeric;$/ { next }
  /^  -- Recent sign-in: the newest amr entry/ { skip = 1 }
  skip { if ($0 ~ /^  end if;$/) { skip = 2 }; if (skip == 2) { skip = 0; getline; if ($0 != "") print }; next }
  { print }
' <<<"$body")
[[ "$without_check" == "$previous_body" ]] ||
  fail "begin_account_deletion without the recent sign-in check must equal its previous definition in $previous"

# Nothing else changes: delete_my_app_data and delete_my_account keep their
# latest definitions in earlier migrations.
for fn in delete_my_app_data delete_my_account; do
  if grep -Eiq "^create (or replace )?function +public\\.$fn *\\(|function +public\\.$fn *\\(" "$migration"; then
    fail "$migration must not change public.$fn"
  fi
done

# Registry and contract -----------------------------------------------------------
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
line=$(grep -E '^\| `TH017` \| `recent_authentication_required` \|' "$contract" || true)
[[ -n "$line" ]] || fail "TH017 recent_authentication_required is not in the registry in $contract"
# shellcheck disable=SC2016
for fn in '`begin_account_deletion`' '`delete_my_account`'; do
  grep -Fq "$fn" <<<"$line" || fail 'the TH017 registry row must name begin_account_deletion and delete_my_account'
done
grep -Fq '| Recent authentication is required |' <<<"$line" || fail 'the TH017 registry row must carry its message'
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_begin_deletion_recent_sign_in.sh`' "$contract" ||
  fail "$contract must name this check"

echo 'Begin-deletion recent sign-in static checks passed.'

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
  echo "$out" | grep -E 'PASS|FAIL|not runnable' || true
  echo "$out" | grep -q 'TH988E_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH988E_CONTROL_STALE_SIGN_IN_REFUSED' ||
    fail 'control: a stale sign-in was not refused, or a recent one did not start deletion'
  echo 'Begin-deletion recent sign-in SQL test and control passed.'
fi
