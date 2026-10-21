#!/usr/bin/env bash
# Checks that consent records are removed only by row deletes: a statement
# trigger on programme_consents and on account_consents refuses TRUNCATE for
# every role, in every session mode, and the deletion paths (delete_my_app_data, deleting an
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

-- Every TRUNCATE form that reaches a consent table, each refused with
-- p_state: TH003 from the guard, or 42501 for a role without the truncate
-- privilege.
create function th987_test.truncates_refused(p_who text, p_state text)
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
begin
  foreach stmt in array array[
    'truncate public.programme_consents',
    'truncate public.programme_consents cascade',
    'truncate public.account_consents',
    'truncate public.account_consents cascade',
    'truncate public.programme_consents, public.account_consents'
  ] loop
    if p_state = 'TH003' then
      perform th987_test.refused(stmt, 'TH003', 'Consent records are immutable',
        p_who || ': ' || stmt || ' is refused', 'consent_immutable');
    else
      perform th987_test.refused(stmt, p_state, 'permission denied%',
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
  'account_consents:account_consents_truncate_guard:34:consent_truncate_guard:A,'
  'programme_consents:programme_consents_truncate_guard:34:consent_truncate_guard:A',
  'consent tables: one truncate trigger each, before truncate, for each statement, consent_truncate_guard, enabled in every session mode');
select th987_test.ok(
  (select t.tgtype::integer = 34 and t.tgenabled = 'A'
   from pg_catalog.pg_trigger as t
   where t.tgrelid = 'public.consent_documents'::regclass
     and t.tgname = 'consent_documents_guard_truncate'),
  'consent_documents: its truncate guard is enabled in every session mode');
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
select th987_test.ok(
  not has_table_privilege('service_role', 'public.programme_consents', 'TRUNCATE')
  and not has_table_privilege('service_role', 'public.account_consents', 'TRUNCATE')
  and not has_table_privilege('service_role', 'public.programme_consents', 'TRIGGER')
  and not has_table_privilege('service_role', 'public.account_consents', 'TRIGGER')
  and not has_table_privilege('service_role', 'public.programme_consents', 'REFERENCES')
  and not has_table_privilege('service_role', 'public.account_consents', 'REFERENCES'),
  'service_role holds no truncate, trigger or references privilege on the consent tables');

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
select th987_test.truncates_refused('superuser', 'TH003');
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
select th987_test.truncates_refused('bypass role', 'TH003');
reset role;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'bypass role: the refused truncates left every consent row untouched');

-- A role subject to row-level security, holding the truncate privilege ---------------
create role th987_plain nologin;
grant usage on schema public to th987_plain;
grant select, truncate on public.programme_consents, public.account_consents to th987_plain;
set local role th987_plain;
select th987_test.truncates_refused('non-bypass role', 'TH003');
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
select th987_test.truncates_refused('table owner', 'TH003');
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
-- Neither holds the truncate privilege, so the privilege check refuses first.
set local role service_role;
select th987_test.truncates_refused('service_role', '42501');
reset role;
set local role authenticated;
select th987_test.truncates_refused('authenticated', '42501');
reset role;
select th987_test.ok(th987_test.fingerprint() = current_setting('th987.consents'),
  'every refused truncate left every consent row untouched');

-- The guards fire in every session mode ----------------------------------------------
select set_config('th987.documents', (select count(*)::text from public.consent_documents), true);
set local session_replication_role = replica;
select th987_test.truncates_refused('superuser, replica session', 'TH003');
select th987_test.refused('truncate public.consent_documents cascade',
  'TH015', 'Consent documents are immutable, publish a new version',
  'superuser, replica session: truncate consent_documents cascade is refused', 'consent_document_immutable');
reset session_replication_role;
select th987_test.ok(
  th987_test.fingerprint() = current_setting('th987.consents')
  and (select count(*)::text from public.consent_documents) = current_setting('th987.documents'),
  'replica session: the refused truncates left every consent row and document untouched');

-- Row deletes still remove consents ---------------------------------------------------
-- "Delete now": A deletes one enrolment; its consent goes with it (cascade).
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000009870a1', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-0000009870a1","role":"authenticated"}', true);
select set_config('request.jwt.claims', (current_setting('request.jwt.claims')::jsonb
  || jsonb_build_object('amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30))))::text, true);
set local role authenticated;
select public.delete_enrolment_now('00000000-0000-4000-8000-00000987e0a2', 'DELETE');
reset role;
select th987_test.ok(
  (select count(*) from public.enrolments where id = '00000000-0000-4000-8000-00000987e0a2') = 0
  and (select count(*) from public.programme_consents
       where enrolment_id = '00000000-0000-4000-8000-00000987e0a2') = 0
  and (select count(*) from public.programme_consents) = 3,
  'A: deleting an enrolment still removes its consents (row delete cascade)');

-- delete_my_app_data, end to end.
-- A recent sign-in, which begin_account_deletion requires.
select set_config('request.jwt.claims', (current_setting('request.jwt.claims')::jsonb
  || jsonb_build_object('amr', jsonb_build_array(jsonb_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30))))::text, true);
set local role authenticated;
select th987_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
-- Owner context, as delete_my_account runs it: the superuser with A's claims.
reset role;
select set_config('th987.a_receipt', public.delete_my_app_data('DELETE')::text, true);
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', '', true);
select th987_test.ok(
  current_setting('th987.a_receipt')::jsonb = '{"profiles": 1, "quit_plans": 0,
    "program_data": 0, "enrolments": 1, "programme_consents": 2, "account_consents": 1,
    "sync_answers": 0, "sync_lapses": 0, "sync_areas": 0, "sync_accounts": 0,
    "care_share_access": 0, "care_messages": 0, "care_shares": 0, "caregiver_events": 0,
    "caregivers": 0, "care_connections": 0, "supporters": 0}'::jsonb,
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
# The guards, and the consent_documents truncate guard, fire in every session mode.
for pair in programme_consents:programme_consents_truncate_guard \
  account_consents:account_consents_truncate_guard \
  consent_documents:consent_documents_guard_truncate; do
  grep -A1 -Fx "alter table public.${pair%%:*}" <<<"$sql" |
    grep -Fxq "enable always trigger ${pair##*:};" ||
    fail "${pair##*:} must be enabled always"
done

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
grep -A1 -Fx 'revoke truncate, trigger, references on public.programme_consents, public.account_consents' <<<"$sql" |
  grep -Fxq 'from service_role;' ||
  fail 'service_role: revoke truncate, trigger and references on the consent tables'
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

# No migration truncates a table, redefines or drops a guard, or changes when
# a guard fires; the only allowed change is enabling a guard always.
# Prints the first problem in the SQL on stdin, or nothing. Comments are
# removed and the text is joined into one lower-case line, so a statement
# split over lines is matched as one. Trigger events ("truncate on") and
# "execute function" in create trigger are not statements and are set aside.
guards='programme_consents_truncate_guard|account_consents_truncate_guard|consent_documents_guard_truncate|sync_account_truncate_guard|sync_area_truncate_guard|sync_answer_truncate_guard|sync_lapse_truncate_guard|care_connections_truncate_guard|care_shares_truncate_guard|care_share_access_truncate_guard|care_messages_truncate_guard|caregivers_truncate_guard|caregiver_events_truncate_guard'
migration_problem() {
  local text change
  text=$(sed 's/--.*$//' | tr '\n\t' '  ' | tr '[:upper:]' '[:lower:]' |
    sed -E 's/ +/ /g; s/(^|[^a-z_])truncate on /\1trigger_event_on /g; s/(^|[^a-z_])execute (function|procedure) /\1runs_\2 /g')
  if grep -Eq "(^|[^a-z_])execute[^;]*[^a-z_]truncate([^a-z_]|\$)" <<<"$text"; then
    echo 'dynamic execute of a truncate'; return
  fi
  if grep -Eq "(^|[^a-z_'])truncate( table)? (only )?[a-z_\".]" <<<"$text"; then
    echo 'truncate statement'; return
  fi
  if grep -Fq 'session_replication_role' <<<"$text"; then
    echo 'sets session_replication_role'; return
  fi
  if grep -Fq 'create or replace function public.consent_truncate_guard' <<<"$text"; then
    echo 'redefines consent_truncate_guard'; return
  fi
  if grep -Eq "drop trigger (if exists )?($guards)([^a-z_]|\$)|drop function (if exists )?public\.consent_truncate_guard" <<<"$text"; then
    echo 'drops a truncate guard'; return
  fi
  while read -r change; do
    [[ -n "$change" ]] || continue
    [[ "$change" =~ ^enable\ always\ trigger\ ($guards)$ ]] || {
      echo "changes when a trigger fires ($change)"; return
    }
  done < <(grep -Eo '(disable|enable)( always| replica)? trigger [a-z_"]+' <<<"$text" || true)
}

# Self-test of the scan; runs every time.
check_scan() {
  local want="$1" got
  shift
  got=$(printf '%s\n' "$@" | migration_problem)
  [[ "$got" == "$want" ]] || fail "migration scan self-test: expected '$want', got '$got' for: $*"
}
check_scan 'truncate statement' 'begin;' 'TRUNCATE' '  public.programme_consents;' 'commit;'
check_scan 'truncate statement' 'truncate table only public.sync_lapse;'
check_scan 'dynamic execute of a truncate' "execute format('truncate %I', t);"
check_scan 'dynamic execute of a truncate' 'perform 1;' "EXECUTE 'TRUNCATE ' ||" "  'public.account_consents';"
check_scan 'sets session_replication_role' 'set local session_replication_role = replica;'
check_scan 'redefines consent_truncate_guard' 'create or replace function public.consent_truncate_guard()'
check_scan 'drops a truncate guard' 'drop trigger if exists programme_consents_truncate_guard' '  on public.programme_consents;'
check_scan 'drops a truncate guard' 'drop function public.consent_truncate_guard();'
check_scan 'changes when a trigger fires (disable trigger account_consents_truncate_guard)' \
  'alter table public.account_consents disable trigger account_consents_truncate_guard;'
check_scan 'changes when a trigger fires (enable trigger account_consents_truncate_guard)' \
  'alter table public.account_consents' 'enable trigger account_consents_truncate_guard;'
check_scan 'changes when a trigger fires (enable replica trigger programme_consents_truncate_guard)' \
  'alter table public.programme_consents enable replica trigger programme_consents_truncate_guard;'
check_scan 'changes when a trigger fires (enable always trigger other_trigger)' \
  'alter table public.enrolments enable always trigger other_trigger;'
check_scan 'changes when a trigger fires (disable trigger all)' 'alter table public.enrolments disable trigger all;'
check_scan '' 'alter table public.account_consents' 'enable always trigger account_consents_truncate_guard;' \
  'create trigger t before insert or truncate on public.t' \
  'for each statement execute function public.consent_truncate_guard();' \
  "  if tg_op = 'TRUNCATE' then" "execute 'select 1';"

for f in "${migration_files[@]}"; do
  problem=$(migration_problem <"$f")
  [[ -z "$problem" ]] || fail "$f: $problem; consent rows are removed with DELETE and the truncate guards stay in place"
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
