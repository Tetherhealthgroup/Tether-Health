#!/usr/bin/env bash
# Checks that consent records are removed only by row deletes: a statement
# trigger on programme_consents and on account_consents refuses TRUNCATE for
# every role, and the deletion paths (delete_my_app_data, deleting an
# enrolment) still remove consent rows with DELETE.
#
#   bash supabase/tests/verify_consent_truncate_guards.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#       The SQL test creates and switches to test roles, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql                     print the SQL test
#
# The SQL test uses synthetic identities only, runs in one transaction and
# always rolls back.
set -euo pipefail

migration="supabase/migrations/202610180005_consent_truncate_guards.sql"
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
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role') then
    raise exception 'FAIL setup: role service_role is missing';
  end if;
end;
$setup$;

create schema th987_test;

create function th987_test.ok(p_cond boolean, p_label text)
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
create function th987_test.refused(
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

-- Every TRUNCATE form that reaches a consent table. The current role must hold
-- the truncate privilege on both consent tables, and each form is refused
-- with TH003 (or hold it on neither, and each is refused with 42501).
create function th987_test.truncates_refused(p_who text)
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
  on_programme boolean := has_table_privilege('public.programme_consents', 'TRUNCATE');
  on_account boolean := has_table_privilege('public.account_consents', 'TRUNCATE');
begin
  if on_programme is distinct from on_account then
    raise exception 'FAIL % holds truncate on one consent table only', p_who;
  end if;
  foreach stmt in array array[
    'truncate public.programme_consents',
    'truncate public.programme_consents cascade',
    'truncate public.account_consents',
    'truncate public.account_consents cascade',
    'truncate public.programme_consents, public.account_consents'
  ] loop
    if on_programme then
      perform th987_test.refused(stmt, 'TH003', 'Consent records are immutable',
        p_who || ': ' || stmt || ' is refused', 'consent_immutable');
    else
      perform th987_test.refused(stmt, '42501', 'permission denied%',
        p_who || ': ' || stmt || ' is refused (no truncate privilege)');
    end if;
  end loop;
end;
$f$;

grant usage on schema th987_test to public;
grant execute on all functions in schema th987_test to public;

-- Catalogue -------------------------------------------------------------------
select th987_test.ok(
  (select string_agg(c.relname || ':' || t.tgname || ':' || t.tgtype || ':' || p.proname
            || ':' || t.tgenabled::text, ',' order by c.relname, t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_class as c on c.oid = t.tgrelid
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where t.tgrelid in ('public.programme_consents'::regclass, 'public.account_consents'::regclass)
     and not t.tgisinternal and (t.tgtype::integer & 32) <> 0) =
  'account_consents:account_consents_truncate_guard:34:consent_truncate_guard:O,'
  'programme_consents:programme_consents_truncate_guard:34:consent_truncate_guard:O',
  'consent tables: one enabled truncate trigger each, before truncate, for each statement, consent_truncate_guard');
select th987_test.ok(
  (select not prosecdef and proconfig = array['search_path=""']
   from pg_catalog.pg_proc where oid = 'public.consent_truncate_guard()'::regprocedure)
  and not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
    where p.oid = 'public.consent_truncate_guard()'::regprocedure
      and (a.grantee = 0 or a.grantee in ('anon'::regrole, 'authenticated'::regrole,
                                          'thsync'::regrole, 'service_role'::regrole))),
  'consent_truncate_guard: security invoker, empty search_path; no execute for anon, authenticated, thsync, service_role or PUBLIC');
select th987_test.ok(
  not has_table_privilege('authenticated', 'public.programme_consents', 'TRUNCATE')
  and not has_table_privilege('authenticated', 'public.account_consents', 'TRUNCATE')
  and not has_table_privilege('anon', 'public.programme_consents', 'TRUNCATE')
  and not has_table_privilege('anon', 'public.account_consents', 'TRUNCATE'),
  'authenticated and anon hold no truncate privilege on the consent tables');

-- Synthetic identities and consents -----------------------------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009870a1', 'synthetic-user-a1@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009870b1', 'synthetic-user-b1@example.test',
   'authenticated', 'authenticated');
insert into public.enrolments (id, user_id, programme_code, status) values
  ('00000000-0000-4000-8000-00000987e0a1', '00000000-0000-4000-8000-0000009870a1', 'hw', 'focus'),
  ('00000000-0000-4000-8000-00000987e0a2', '00000000-0000-4000-8000-0000009870a1', 'st', 'learn_only'),
  ('00000000-0000-4000-8000-00000987e0b1', '00000000-0000-4000-8000-0000009870b1', 'hw', 'focus');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-00000987e0a1', 'core', 'v1-draft', 'en'),
  ('00000000-0000-4000-8000-00000987e0a1', 'reminders', 'v1-draft', 'en'),
  ('00000000-0000-4000-8000-00000987e0a2', 'core', 'v1-draft', 'es'),
  ('00000000-0000-4000-8000-00000987e0b1', 'core', 'v1-draft', 'en');
-- Revoked history on A's first enrolment.
update public.programme_consents set revoked_at = now()
where enrolment_id = '00000000-0000-4000-8000-00000987e0a1' and purpose = 'reminders';
insert into public.account_consents (user_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-0000009870a1', 'essential', 'v1-draft', 'en'),
  ('00000000-0000-4000-8000-0000009870b1', 'essential', 'v1-draft', 'es');

-- A fingerprint of every consent row, to show refused truncates change nothing.
create function th987_test.fingerprint()
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.md5(
    coalesce((select string_agg(pg_catalog.to_jsonb(c)::text, '|' order by c.id)
              from public.programme_consents as c), '') || '#' ||
    coalesce((select string_agg(pg_catalog.to_jsonb(c)::text, '|' order by c.id)
              from public.account_consents as c), '') || '#' ||
    (select count(*)::text from public.programme_consents) || '/' ||
    (select count(*)::text from public.account_consents))
$f$;
grant execute on function th987_test.fingerprint() to public;
select set_config('th987.consents', th987_test.fingerprint(), true);
select th987_test.ok(
  (select count(*) from public.programme_consents) = 4
  and (select count(*) from public.account_consents) = 2,
  'setup: 4 programme consents (1 revoked) and 2 account consents');

-- Superuser (as a migration runs) --------------------------------------------------
select th987_test.truncates_refused('superuser');
-- Truncating a table the consent tables reference: without CASCADE the
-- foreign keys refuse first (0A000); with CASCADE it reaches a consent table
-- and the guard refuses. The focus-cap check on the enrolments inserted above
-- is deferred to commit; it runs now, so no trigger event is pending on
-- enrolments, and is deferred again afterwards.
set constraints public.enrolments_focus_cap immediate;
select th987_test.refused('truncate public.enrolments',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'superuser: truncate enrolments without cascade is refused');
select th987_test.refused('truncate public.enrolments cascade',
  'TH003', 'Consent records are immutable',
  'superuser: truncate enrolments cascade (reaches programme_consents) is refused', 'consent_immutable');
set constraints public.enrolments_focus_cap deferred;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'superuser: the refused truncates left every consent row untouched');

-- A role that bypasses row-level security --------------------------------------------
create role th987_bypass nologin bypassrls;
grant usage on schema public to th987_bypass;
grant select, truncate on public.programme_consents, public.account_consents to th987_bypass;
set local role th987_bypass;
select th987_test.ok(
  (select count(*) from public.programme_consents) = 4,
  'bypass role: sees every consent row (it holds truncate and select)');
select th987_test.truncates_refused('bypass role');
reset role;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'bypass role: the refused truncates left every consent row untouched');

-- A role subject to row-level security, holding the truncate privilege ---------------
create role th987_plain nologin;
grant usage on schema public to th987_plain;
grant select, truncate on public.programme_consents, public.account_consents to th987_plain;
set local role th987_plain;
select th987_test.truncates_refused('non-bypass role');
reset role;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'non-bypass role: the refused truncates left every consent row untouched');

-- The table owner, when it is not a superuser ----------------------------------------
create role th987_owner nologin;
grant usage on schema public to th987_owner;
select set_config('th987.owner',
  (select relowner::regrole::text from pg_catalog.pg_class
   where oid = 'public.programme_consents'::regclass), true);
alter table public.programme_consents owner to th987_owner;
alter table public.account_consents owner to th987_owner;
set local role th987_owner;
select th987_test.truncates_refused('table owner');
reset role;
do $restore$
begin
  execute pg_catalog.format('alter table public.programme_consents owner to %s', current_setting('th987.owner'));
  execute pg_catalog.format('alter table public.account_consents owner to %s', current_setting('th987.owner'));
end;
$restore$;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'table owner: the refused truncates left every consent row untouched');

-- service_role and authenticated -----------------------------------------------------
-- service_role is refused by the trigger when it holds the truncate privilege
-- (as Supabase's default grants give it), by the missing privilege otherwise.
set local role service_role;
select th987_test.truncates_refused('service_role');
reset role;
set local role authenticated;
select th987_test.truncates_refused('authenticated');
reset role;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'every refused truncate left every consent row untouched');

-- Row deletes still remove consents ---------------------------------------------------
-- "Delete now": A deletes one enrolment; its consent goes with it (cascade).
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000009870a1', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000009870a1","role":"authenticated"}', true);
set local role authenticated;
delete from public.enrolments where id = '00000000-0000-4000-8000-00000987e0a2';
reset role;
select th987_test.ok(
  (select count(*) from public.enrolments where id = '00000000-0000-4000-8000-00000987e0a2') = 0
  and (select count(*) from public.programme_consents
       where enrolment_id = '00000000-0000-4000-8000-00000987e0a2') = 0
  and (select count(*) from public.programme_consents) = 3,
  'A: deleting an enrolment still removes its consents (row delete cascade)');

-- delete_my_app_data, end to end.
set local role authenticated;
select th987_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
select set_config('th987.a_receipt', public.delete_my_app_data('DELETE')::text, true);
reset role;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '', true);
select th987_test.ok(
  current_setting('th987.a_receipt')::jsonb = '{"profiles": 1, "quit_plans": 0,
    "program_data": 0, "enrolments": 1, "programme_consents": 2, "account_consents": 1,
    "sync_answers": 0, "sync_lapses": 0, "sync_areas": 0, "sync_accounts": 0}'::jsonb,
  'A: delete_my_app_data deletes A''s consents (live and revoked) and returns the counts');
select th987_test.ok(
  (select count(*) from public.profiles where id = '00000000-0000-4000-8000-0000009870a1') = 0
  and (select count(*) from public.enrolments where user_id = '00000000-0000-4000-8000-0000009870a1') = 0
  and (select count(*) from public.programme_consents
       where enrolment_id = '00000000-0000-4000-8000-00000987e0a1') = 0
  and (select count(*) from public.account_consents
       where user_id = '00000000-0000-4000-8000-0000009870a1') = 0,
  'A: no profile, enrolment, programme consent or account consent of A is left');
select th987_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = '00000000-0000-4000-8000-00000987e0b1') = 1
  and (select count(*) from public.account_consents
       where user_id = '00000000-0000-4000-8000-0000009870b1') = 1,
  'B: deleting A left B''s consents untouched');

select 'TH987_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Consent truncate guard check failed: $1" >&2
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

sql=$(sed 's/--.*$//' "$migration")

# Each consent table has a before-truncate statement trigger on the guard.
for table in programme_consents account_consents; do
  grep -A2 "^create trigger ${table}_truncate_guard\$" <<<"$sql" | tr '\n' ' ' |
    grep -Fq "before truncate on public.$table for each statement execute function public.consent_truncate_guard();" ||
    fail "${table}_truncate_guard must run consent_truncate_guard before truncate, for each statement"
done
[[ "$(grep -Ec '^create trigger ' <<<"$sql")" -eq 2 ]] ||
  fail 'this migration creates exactly the two truncate triggers'

# The guard refuses unconditionally, with TH003 and its registered hint.
body=$(sed -n '/^create function public\.consent_truncate_guard()$/,/^\$\$;$/p' <<<"$sql")
[[ -n "$body" ]] || fail 'missing public.consent_truncate_guard()'
grep -Fxq 'security invoker' <<<"$body" || fail 'consent_truncate_guard must be security invoker'
grep -Fxq "set search_path = ''" <<<"$body" || fail "consent_truncate_guard must set search_path = ''"
[[ "$(sed -n '/^begin$/,/^end;$/p' <<<"$body" | tr -s ' \n' ' ')" == \
  "begin raise exception using errcode = 'TH003', message = 'Consent records are immutable', hint = 'consent_immutable'; end; " ]] ||
  fail 'consent_truncate_guard must only raise TH003 (Consent records are immutable, consent_immutable), whatever the role'

# Privileges and hygiene.
grep -A1 -Fx 'revoke all on function public.consent_truncate_guard()' <<<"$sql" |
  grep -Fxq 'from public, anon, authenticated, service_role;' ||
  fail 'consent_truncate_guard: revoke from public, anon, authenticated and service_role'
[[ "$(grep -Ec '^create (or replace )?function ' <<<"$sql")" -eq 1 ]] ||
  fail 'this migration creates one function'
if grep -Eq '^security definer$' <<<"$sql"; then
  fail 'no function in this migration may be security definer'
fi
if grep -Eiq '^grant ' <<<"$sql"; then
  fail 'this migration grants nothing'
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

# No migration truncates a table, and none removes or disables these triggers.
for f in "${migration_files[@]}"; do
  stripped=$(sed 's/--.*$//' "$f")
  if grep -Eiv '(before|after) truncate on ' <<<"$stripped" |
    grep -Eiq '(^|[;[:space:]])truncate([[:space:]]+table)?[[:space:]]+(only[[:space:]]+)?[a-z_."]+'; then
    fail "$f issues a TRUNCATE; remove rows with DELETE"
  fi
  if grep -Eiq 'drop trigger (if exists )?(programme|account)_consents_truncate_guard|drop function (if exists )?public\.consent_truncate_guard|(disable|enable)[a-z ]* trigger' <<<"$stripped"; then
    fail "$f removes or changes a trigger; consent truncate guards stay enabled"
  fi
done

# The latest delete_my_app_data removes consents with DELETE.
latest=$(grep -El '^create (or replace )?function public\.delete_my_app_data\(' "${migration_files[@]}" | tail -n 1)
[[ -n "$latest" ]] || fail 'no definition of public.delete_my_app_data'
delete_body=$(sed -n '/^create \(or replace \)\{0,1\}function public\.delete_my_app_data(/,/^\$\$;/p' "$latest")
grep -Fxq '  delete from public.programme_consents' <<<"$delete_body" ||
  fail 'delete_my_app_data must delete programme consents with DELETE'
grep -Fq '  delete from public.account_consents where user_id = caller_id;' <<<"$delete_body" ||
  fail 'delete_my_app_data must delete account consents with DELETE'
if grep -Eiq '(^|[^a-z_])truncate([^a-z_]|$)' <<<"$delete_body"; then
  fail 'delete_my_app_data must not truncate'
fi

# Registry: TH003 names the guard and carries its message.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
row=$(grep -E '^\| `TH003` \| `consent_immutable` \|' "$contract" || true)
[[ -n "$row" ]] || fail 'TH003 consent_immutable is not in the registry'
# shellcheck disable=SC2016
grep -Fq '`consent_truncate_guard`' <<<"$row" || fail 'the TH003 registry row must name consent_truncate_guard'
grep -Fq 'Consent records are immutable' <<<"$row" || fail 'the TH003 registry row must carry its message'

# The contract names this migration and the rule it adds.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq 'A trigger refuses `TRUNCATE` on `programme_consents` and `account_consents` for every role' "$contract" ||
  fail "$contract must state that a trigger refuses TRUNCATE on the consent tables for every role"

echo 'Consent truncate guard static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH987_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  echo 'Consent truncate guard SQL test passed.'
fi
