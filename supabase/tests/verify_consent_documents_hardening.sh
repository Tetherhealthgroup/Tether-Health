#!/usr/bin/env bash
# Checks that consent documents are published only by migrations: the guard
# also covers delete, nobody truncates documents, service_role may only read,
# and every locale of a version keeps one effective_from while one statement
# may move an unreferenced version.
#
#   bash supabase/tests/verify_consent_documents_hardening.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#       The SQL test creates and switches to test roles, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql                     print the SQL test
#
# The SQL test uses synthetic identities and synthetic consent texts only,
# runs in one transaction and always rolls back.
set -euo pipefail

migration="supabase/migrations/202610180004_consent_documents_hardening.sql"
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

create schema th981_test;

create function th981_test.ok(p_cond boolean, p_label text)
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
create function th981_test.refused(
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

create function th981_test.affects(p_sql text, p_rows integer, p_label text)
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

grant usage on schema th981_test to public;
grant execute on all functions in schema th981_test to public;

-- Catalogue -------------------------------------------------------------------
-- The truncate guard is enabled always (A) by 202610180005_consent_truncate_guards.sql.
select th981_test.ok(
  (select string_agg(t.tgname || ':' || t.tgtype || ':' || p.proname || ':'
            || coalesce(t.tgnewtable::text, '-') || ':' || t.tgenabled::text, ',' order by t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where t.tgrelid = 'public.consent_documents'::regclass and not t.tgisinternal) =
  'consent_documents_guard:31:consent_documents_guard:-:O,'
  'consent_documents_guard_truncate:34:consent_documents_guard:-:A,'
  'consent_documents_same_effective_from_insert:4:consent_documents_check_effective_from:written_documents:O,'
  'consent_documents_same_effective_from_update:16:consent_documents_check_effective_from:written_documents:O',
  'consent_documents triggers: guard before insert, update and delete (row) and truncate (in every session mode); effective_from check after each insert and update statement');
-- Tripwire: the table privileges anyone but the owner holds on consent_documents.
select th981_test.ok(
  (select string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ','
            order by a.grantee::regrole::text, a.privilege_type)
   from pg_catalog.pg_class as c
   cross join lateral pg_catalog.aclexplode(
     coalesce(c.relacl, pg_catalog.acldefault('r', c.relowner))) as a
   where c.oid = 'public.consent_documents'::regclass and a.grantee <> c.relowner) =
  'authenticated:SELECT,service_role:SELECT'
  and not exists (
    select 1 from pg_catalog.pg_attribute
    where attrelid = 'public.consent_documents'::regclass and attacl is not null),
  'consent_documents privileges: only select, for authenticated and service_role; no column grants');
select th981_test.ok(
  has_table_privilege('service_role', 'public.consent_documents', 'SELECT')
  and not has_any_column_privilege('service_role', 'public.consent_documents', 'INSERT')
  and not has_any_column_privilege('service_role', 'public.consent_documents', 'UPDATE')
  and not has_table_privilege('service_role', 'public.consent_documents', 'DELETE')
  and not has_table_privilege('service_role', 'public.consent_documents', 'TRUNCATE')
  and not has_table_privilege('service_role', 'public.consent_documents', 'TRIGGER')
  and not has_table_privilege('service_role', 'public.consent_documents', 'REFERENCES'),
  'service_role: may read consent documents, may not write them');
select th981_test.ok(
  (select bool_and(not prosecdef and proconfig = array['search_path=""'])
   from pg_catalog.pg_proc
   where oid in ('public.consent_documents_guard()'::regprocedure,
                 'public.consent_documents_check_effective_from()'::regprocedure))
  and not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
    where p.oid in ('public.consent_documents_guard()'::regprocedure,
                    'public.consent_documents_check_effective_from()'::regprocedure)
      and (a.grantee = 0 or a.grantee in ('anon'::regrole, 'authenticated'::regrole,
                                          'thsync'::regrole, 'service_role'::regrole))),
  'guard functions: security invoker, empty search_path; no execute for anon, authenticated, thsync, service_role or PUBLIC');

-- Synthetic identity and documents -----------------------------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009810a1', 'synthetic-user-a1@example.test',
   'authenticated', 'authenticated');
-- A consent references essential/v1-draft/en.
insert into public.account_consents (user_id, purpose, consent_version, locale)
values ('00000000-0000-4000-8000-0000009810a1', 'essential', 'v1-draft', 'en');
insert into public.consent_documents
  (purpose, version, locale, body, effective_from, cascades_optional) values
  ('research', 'v6-unref', 'en', 'Synthetic research text v6', now() - interval '1 hour', false),
  ('core', 'v6-flag', 'en', 'Synthetic core text v6', now() - interval '1 hour', true),
  ('core', 'v6-flag', 'es', 'Synthetic core text v6 (es)', now() - interval '1 hour', true);
select set_config('th981.documents', (select count(*)::text from public.consent_documents), true);

-- service_role reads but never writes documents ------------------------------------
-- On Supabase service_role bypasses row-level security and reads every
-- document. A service_role without that attribute (as in a plain Postgres
-- stand-in) reads none: consent_documents forces row-level security and has
-- no policy for service_role. Either way the select itself is permitted.
select set_config('th981.service_role_bypass',
  (select rolbypassrls::text from pg_catalog.pg_roles where rolname = 'service_role'), true);
set local role service_role;
select th981_test.ok(
  (select count(*)::text from public.consent_documents) =
  case when current_setting('th981.service_role_bypass')::boolean
       then current_setting('th981.documents') else '0' end,
  'service_role: reads every document when it bypasses row-level security, none otherwise');
select th981_test.refused(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from)
   values (''research'', ''v6-svc'', ''en'', ''Synthetic'', now())',
  '42501', 'permission denied%', 'service_role: cannot add a consent document');
select th981_test.refused(
  'update public.consent_documents set retired_at = now() + interval ''1 day''
   where purpose = ''research'' and version = ''v6-unref''',
  '42501', 'permission denied%', 'service_role: cannot change a consent document');
select th981_test.refused(
  'delete from public.consent_documents where purpose = ''research'' and version = ''v6-unref''',
  '42501', 'permission denied%', 'service_role: cannot delete a consent document');
select th981_test.refused(
  'truncate public.consent_documents, public.programme_consents, public.account_consents',
  '42501', 'permission denied%', 'service_role: cannot truncate consent documents');
reset role;

-- Deletes need a role that bypasses row-level security ------------------------------
-- A role subject to row-level security, with every table privilege and a
-- policy that shows it every document, still cannot remove one.
create role th981_doc_editor nologin;
grant usage on schema public to th981_doc_editor;
grant select, insert, update, delete, truncate on public.consent_documents to th981_doc_editor;
grant select, truncate on public.programme_consents, public.account_consents to th981_doc_editor;
create policy th981_doc_editor_all on public.consent_documents
  for all to th981_doc_editor using (true) with check (true);
set local role th981_doc_editor;
select th981_test.ok(
  (select count(*) from public.consent_documents)::text = current_setting('th981.documents'),
  'non-bypass role: its policy shows it every document');
select th981_test.refused(
  'delete from public.consent_documents where purpose = ''research'' and version = ''v6-unref''',
  'TH015', 'Consent documents are changed only by a role that bypasses row-level security',
  'non-bypass role: cannot delete an unreferenced document', 'consent_document_immutable');
select th981_test.refused(
  'delete from public.consent_documents where purpose = ''core'' and version = ''v6-flag'' and locale = ''es''',
  'TH015', 'Consent documents are changed only by a role that bypasses row-level security',
  'non-bypass role: cannot delete one locale of a cascades_optional version', 'consent_document_immutable');
select th981_test.refused(
  'delete from public.consent_documents where purpose = ''essential'' and version = ''v1-draft'' and locale = ''en''',
  'TH015', 'Consent documents are changed only by a role that bypasses row-level security',
  'non-bypass role: cannot delete a referenced document', 'consent_document_immutable');
select th981_test.refused(
  'delete from public.consent_documents',
  'TH015', 'Consent documents are changed only by a role that bypasses row-level security',
  'non-bypass role: cannot delete every document', 'consent_document_immutable');
select th981_test.refused(
  'truncate public.consent_documents, public.programme_consents, public.account_consents',
  'TH015', 'Consent documents are immutable, publish a new version',
  'non-bypass role: cannot truncate consent documents', 'consent_document_immutable');
reset role;
select th981_test.ok(
  (select count(*)::text from public.consent_documents) = current_setting('th981.documents')
  and (select count(*) from public.account_consents) = 1,
  'the refused deletes removed nothing');

-- A role that bypasses row-level security removes only unreferenced documents.
create role th981_doc_publisher nologin bypassrls;
grant usage on schema public to th981_doc_publisher;
grant select, delete, truncate on public.consent_documents to th981_doc_publisher;
grant select, truncate on public.programme_consents, public.account_consents to th981_doc_publisher;
set local role th981_doc_publisher;
select th981_test.refused(
  'truncate public.consent_documents, public.programme_consents, public.account_consents',
  'TH015', 'Consent documents are immutable, publish a new version',
  'bypass role: cannot truncate consent documents', 'consent_document_immutable');
select th981_test.affects(
  'delete from public.consent_documents where purpose = ''research'' and version = ''v6-unref''',
  1, 'bypass role: deletes an unreferenced document');
select th981_test.refused(
  'delete from public.consent_documents where purpose = ''essential'' and version = ''v1-draft'' and locale = ''en''',
  '23503', '%account_consents_document_fkey%', 'bypass role: a referenced document cannot be deleted (foreign key)');
reset role;
select th981_test.affects(
  'delete from public.consent_documents where purpose = ''core'' and version = ''v6-flag''',
  2, 'superuser: deletes an unreferenced version, every locale');

-- Nobody truncates documents, not even a superuser ----------------------------------
select set_config('th981.documents', (select count(*)::text from public.consent_documents), true);
insert into public.enrolments (id, user_id, programme_code)
values ('00000000-0000-4000-8000-00000981e0a1', '00000000-0000-4000-8000-0000009810a1', 'hw');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values ('00000000-0000-4000-8000-00000981e0a1', 'core', 'v1-draft', 'en');
-- Without CASCADE the foreign keys refuse first (0A000); with CASCADE, or
-- naming the consent tables, the guard refuses.
select th981_test.refused('truncate public.consent_documents',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'superuser: truncate without cascade is refused');
select th981_test.refused('truncate public.consent_documents cascade',
  'TH015', 'Consent documents are immutable, publish a new version',
  'superuser: truncate cascade is refused', 'consent_document_immutable');
select th981_test.refused(
  'truncate public.consent_documents, public.programme_consents, public.account_consents',
  'TH015', 'Consent documents are immutable, publish a new version',
  'superuser: truncating documents with the consent tables is refused', 'consent_document_immutable');
select th981_test.ok(
  (select count(*)::text from public.consent_documents) = current_setting('th981.documents')
  and (select count(*) from public.programme_consents) = 1
  and (select count(*) from public.account_consents) = 1,
  'superuser: the refused truncates left documents, programme consents and account consents untouched');

-- One statement reschedules an unreferenced version -------------------------------
insert into public.consent_documents (purpose, version, locale, body, effective_from) values
  ('core', 'v7-move', 'en', 'Synthetic core text v7', now() + interval '1 day'),
  ('core', 'v7-move', 'es', 'Synthetic core text v7 (es)', now() + interval '1 day'),
  ('reminders', 'v7-move', 'en', 'Synthetic reminder text v7', now() + interval '1 day'),
  ('reminders', 'v7-move', 'es', 'Synthetic reminder text v7 (es)', now() + interval '1 day');
select th981_test.affects(
  'update public.consent_documents set effective_from = now() + interval ''3 days''
   where purpose = ''core'' and version = ''v7-move''',
  2, 'superuser: one update moves every locale of an unreferenced version');
select th981_test.ok(
  (select count(*) = 2 and bool_and(effective_from = now() + interval '3 days')
   from public.consent_documents where purpose = 'core' and version = 'v7-move'),
  'superuser: both locales now take effect at the new time');
select th981_test.affects(
  'update public.consent_documents set effective_from = now() + interval ''2 days''
   where version = ''v7-move''',
  4, 'superuser: one update moves two unreferenced versions, every locale');
select th981_test.refused(
  'update public.consent_documents set effective_from = now() + interval ''4 days''
   where purpose = ''core'' and version = ''v7-move'' and locale = ''en''',
  'TH015', 'A consent document version takes effect at the same time in every locale',
  'superuser: moving one locale alone is refused', 'consent_document_immutable');
select th981_test.refused(
  'update public.consent_documents
   set effective_from = case locale when ''en'' then now() + interval ''4 days''
                                    else now() + interval ''5 days'' end
   where purpose = ''core'' and version = ''v7-move''',
  'TH015', 'A consent document version takes effect at the same time in every locale',
  'superuser: one update that moves the locales to different times is refused', 'consent_document_immutable');
select th981_test.ok(
  (select count(*) = 4 and bool_and(effective_from = now() + interval '2 days')
   from public.consent_documents where version = 'v7-move'),
  'superuser: the refused updates changed nothing');
select th981_test.refused(
  'update public.consent_documents set effective_from = effective_from - interval ''1 day''
   where purpose = ''essential'' and version = ''v1-draft''',
  'TH015', 'Consent documents are immutable, publish a new version',
  'superuser: a version a consent references cannot be rescheduled', 'consent_document_immutable');
select th981_test.affects(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from)
   values (''diagnostics'', ''v7-one'', ''en'', ''Synthetic diagnostics text v7'', now() + interval ''1 day'')',
  1, 'superuser: adds the en locale of a new version');
select th981_test.affects(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from)
   values (''diagnostics'', ''v7-one'', ''es'', ''Synthetic diagnostics text v7 (es)'', now() + interval ''1 day'')',
  1, 'superuser: adds its es locale at the same time in a later statement');
select th981_test.refused(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from) values
     (''research'', ''v8-multi'', ''en'', ''Synthetic research text v8'', now() + interval ''1 day''),
     (''research'', ''v8-multi'', ''es'', ''Synthetic research text v8 (es)'', now() + interval ''1 day''),
     (''screen_time'', ''v8-multi'', ''en'', ''Synthetic screen text v8'', now() + interval ''1 day''),
     (''screen_time'', ''v8-multi'', ''es'', ''Synthetic screen text v8 (es)'', now() + interval ''2 days'')',
  'TH015', 'A consent document version takes effect at the same time in every locale',
  'superuser: one insert of two versions, the second with different times, is refused', 'consent_document_immutable');
select th981_test.refused(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from, retired_at) values
     (''research'', ''v8-ret'', ''en'', ''Synthetic research text v8r'', now() - interval ''3 days'', now() - interval ''1 day''),
     (''research'', ''v8-ret'', ''es'', ''Synthetic research text v8r (es)'', now() - interval ''2 days'', now() - interval ''1 day'')',
  'TH015', 'A consent document version takes effect at the same time in every locale',
  'superuser: retired locales of one version with different times are refused', 'consent_document_immutable');

select 'TH981_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Consent document hardening check failed: $1" >&2
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

sql=$(sed 's/--.*$//' "$migration")
# Prints the body of one function in this migration.
body_of() {
  sed -n "/^create \\(or replace \\)\\{0,1\\}function public\\.$1(/,/^\\\$\\\$;/p" "$migration"
}

# The guard covers every write, and refuses the role first.
grep -A2 '^create trigger consent_documents_guard$' <<<"$sql" |
  grep -Fq 'before insert or update or delete on public.consent_documents' ||
  fail 'consent_documents_guard must run before insert, update and delete'
grep -A2 '^create trigger consent_documents_guard$' <<<"$sql" |
  grep -Fq 'for each row execute function public.consent_documents_guard();' ||
  fail 'consent_documents_guard must run for each row'
grep -A2 '^create trigger consent_documents_guard_truncate$' <<<"$sql" |
  grep -Fq 'before truncate on public.consent_documents' ||
  fail 'consent_documents_guard must also run before truncate'
guard=$(body_of consent_documents_guard)
role_line=$(grep -n 'r.rolname = current_user and (r.rolsuper or r.rolbypassrls)' <<<"$guard" | cut -d: -f1 || true)
truncate_line=$(grep -n "^  if tg_op = 'TRUNCATE' then$" <<<"$guard" | cut -d: -f1 || true)
if ! { [[ -n "$role_line" && -n "$truncate_line" ]] && ((truncate_line < role_line)) &&
  grep -A1 "^  if tg_op = 'TRUNCATE' then$" <<<"$guard" | grep -Fq "raise exception using errcode = 'TH015',"; }; then
  fail 'consent_documents_guard must refuse every truncate, before the role check'
fi
lock_line=$(grep -nF "  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('consent_documents:' || new.purpose || ':' || new.version, 0));" <<<"$guard" | cut -d: -f1 || true)
if ! { [[ -n "$lock_line" && -n "$role_line" ]] && ((role_line < lock_line)); }; then
  fail 'consent_documents_guard must take the per-version advisory lock after the role check'
fi
delete_line=$(grep -n "^  if tg_op = 'DELETE' then$" <<<"$guard" | cut -d: -f1 || true)
if ! { [[ -n "$role_line" && -n "$delete_line" ]] && ((role_line < delete_line)) &&
  grep -A1 "^  if tg_op = 'DELETE' then$" <<<"$guard" | grep -Fxq '    return old;'; }; then
  fail 'consent_documents_guard must refuse a non-bypass role before it lets a delete through'
fi
if grep -Fq 'd.locale <> new.locale' <<<"$guard"; then
  fail 'the cross-locale effective_from rule runs per statement, not per row'
fi

# Every locale of a version keeps one effective_from, checked per statement.
for event in insert update; do
  grep -A3 "^create trigger consent_documents_same_effective_from_$event\$" <<<"$sql" |
    tr '\n' ' ' | grep -Fq "after $event on public.consent_documents referencing new table as written_documents for each statement execute function public.consent_documents_check_effective_from();" ||
    fail "consent_documents_same_effective_from_$event must run after each $event statement"
done
check=$(body_of consent_documents_check_effective_from)
grep -Fq 'where d.locale <> w.locale and d.effective_from <> w.effective_from' <<<"$check" ||
  fail 'consent_documents_check_effective_from must refuse a different effective_from in either direction'

# Privileges: service_role may only read; nothing else changes.
grep -Fxq 'revoke all on table public.consent_documents from service_role;' <<<"$sql" ||
  fail 'consent_documents: revoke every table privilege from service_role'
grep -Fxq 'grant select on table public.consent_documents to service_role;' <<<"$sql" ||
  fail 'consent_documents: service_role keeps select'
[[ "$(grep -Ec '^grant ' <<<"$sql")" -eq 1 ]] ||
  fail 'the only grant in this migration is select on consent_documents to service_role'
[[ "$(grep -Eic 'service[_-]?role' <<<"$sql")" -eq 4 ]] ||
  fail 'service_role appears only in the table revoke, the select grant and the two function revokes'
grep -A1 -Fx 'revoke all on function public.consent_documents_guard()' <<<"$sql" |
  grep -Fxq 'from service_role;' || fail 'consent_documents_guard: revoke from service_role'
if grep -Eiq '^(create|drop|alter) policy ' <<<"$sql"; then
  fail 'this migration does not change policies'
fi
if grep -Eiq 'disable row level security|no force row level security|(^|[^a-z_])bypassrls|(create|alter|drop) role|owner to|disable trigger' <<<"$sql"; then
  fail 'migration must not weaken RLS, change roles or disable triggers'
fi
if grep -Eiq 'secret|password[[:space:]]*=' <<<"$sql"; then
  fail 'migration must not contain credentials'
fi

# Function hygiene.
functions=$(grep -Ec '^create (or replace )?function ' <<<"$sql")
pinned=$(grep -Ec "^set search_path = ''$" <<<"$sql")
[[ "$functions" -eq 2 && "$pinned" -eq 2 ]] ||
  fail "expected 2 functions, both with search_path = '' (got $functions, $pinned)"
if grep -Eq '^security definer$' <<<"$sql"; then
  fail 'no function in this migration may be security definer'
fi
grep -Fxq 'revoke all on function public.consent_documents_check_effective_from()' <<<"$sql" ||
  fail 'consent_documents_check_effective_from: revoke all'
grep -A1 -Fx 'revoke all on function public.consent_documents_check_effective_from()' <<<"$sql" |
  grep -Fxq 'from public, anon, authenticated, service_role;' ||
  fail 'consent_documents_check_effective_from: revoke from public, anon, authenticated and service_role'
if grep -Eq '^grant execute ' <<<"$sql"; then
  fail 'trigger functions are executed by nobody directly'
fi

# Registry consistency: every raise in this migration uses a registered code
# with its registered hint and message, and its row names the raising function.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
fn_re='^create (or replace )?function public\.([a-z_]+)\('
raise_re="errcode = '(TH[0-9]{3})', message = '([^']+)', hint = '([a-z_]+)';"
expected_raises=6
checked=0
current_fn=''
while IFS= read -r line; do
  if [[ "$line" =~ $fn_re ]]; then
    current_fn="${BASH_REMATCH[2]}"
    continue
  fi
  [[ "$line" =~ $raise_re ]] || fail "unexpected raise form in $current_fn: $line"
  code="${BASH_REMATCH[1]}" msg="${BASH_REMATCH[2]}" hint="${BASH_REMATCH[3]}"
  [[ "$code" == TH015 ]] || fail "$current_fn raises $code; this migration reuses TH015 only"
  row=$(registry_row "$code")
  [[ -n "$row" ]] || fail "$code ($current_fn) is not in the registry"
  grep -Fq "| \`$code\` | \`$hint\` |" <<<"$row" || fail "$code is raised with hint $hint, not the registered name"
  grep -Fq "$msg" <<<"$row" || fail "$code message '$msg' is not in its registry row"
  grep -Fq "\`$current_fn\`" <<<"$row" || fail "$code registry row does not name $current_fn"
  checked=$((checked + 1))
done < <(sed 's/--.*$//' "$migration" | awk '
  /^create (or replace )?function public\./ { print; next }
  /raise exception using errcode/ { stmt = $0; grab = 1 }
  grab {
    if (stmt != $0) { line = $0; sub(/^ +/, "", line); stmt = stmt " " line }
    if ($0 ~ /;$/) { sub(/^ +/, "", stmt); print stmt; grab = 0 }
  }
')
[[ "$checked" -eq "$expected_raises" ]] ||
  fail "expected $expected_raises TH raises in $migration, checked $checked"

# The contract names this migration and the rules it adds.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -E '^\| `TH001` \|' "$contract" | grep -Fq '`swap_focus`' ||
  fail 'the TH001 registry row must say swap_focus raises it'

echo 'Consent document hardening static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH981_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  echo 'Consent document hardening SQL test passed.'
fi
