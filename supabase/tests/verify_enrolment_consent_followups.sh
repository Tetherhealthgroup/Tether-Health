#!/usr/bin/env bash
# Checks for the focus swap, consent documents and core-consent supersession.
#
#   bash supabase/tests/verify_enrolment_consent_followups.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#       The SQL test switches the session user to thsync and to authenticator
#       (the PostgREST login role), so the URL's user must be a superuser.
#   bash <this script> --print-sql                     print the SQL test
#
# The SQL test uses synthetic identities and synthetic consent texts only,
# runs in one transaction and always rolls back.
set -euo pipefail

migration="supabase/migrations/202610180003_enrolment_consent_followups.sql"
contract="docs/contracts/database.md"

# The release gate query documented in the contract (between its markers).
release_gate_sql() {
  sed -n '/^<!-- release-gate:begin -->$/,/^<!-- release-gate:end -->$/p' "$contract" |
    sed -e '1,2d' | sed -e '$d' | sed -e '$d'
}

print_sql() {
  local gate
  gate=$(release_gate_sql)
  [[ -n "$gate" ]] || { echo 'release gate block missing from the contract' >&2; return 1; }
  local line
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
    raise exception 'FAIL setup: this SQL test needs a superuser connection (it switches the session user to thsync and authenticator)';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticator') then
    raise exception 'FAIL setup: role authenticator (the PostgREST login role) is missing';
  end if;
end;
$setup$;

select set_config('th972b.superuser', session_user, true);

create schema th972b_test;

create function th972b_test.ok(p_cond boolean, p_label text)
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
create function th972b_test.refused(
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

create function th972b_test.affects(p_sql text, p_rows integer, p_label text)
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

-- Runs statements in order, as one unit (wrap in refused() to roll it back).
create function th972b_test.run(p_sql text[])
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
begin
  foreach stmt in array p_sql loop
    execute stmt;
  end loop;
end;
$f$;

-- Runs p_setup, evaluates p_probe (a query returning one text value), then
-- undoes the setup and returns the probe's value.
create function th972b_test.after(p_setup text[], p_probe text)
returns text language plpgsql as $f$
declare
  stmt text;
  result text;
begin
  begin
    foreach stmt in array p_setup loop
      execute stmt;
    end loop;
    execute p_probe into result;
    raise exception using errcode = 'P0001', message = 'th972b-undo', detail = coalesce(result, '<null>');
  exception when sqlstate 'P0001' then
    if sqlerrm <> 'th972b-undo' then
      raise;
    end if;
    get stacked diagnostics result = pg_exception_detail;
  end;
  return result;
end;
$f$;

-- The consent release gate, exactly as documented in docs/contracts/database.md
-- (the verify script inserts the documented block here).
create function th972b_test.release_gate()
returns table (reason text, purpose text, version text, locale text)
language sql as $f$
-- @RELEASE_GATE@
$f$;

create function th972b_test.gate_reasons()
returns text language sql as $f$
  select coalesce(string_agg(distinct reason, ',' order by reason), '')
  from th972b_test.release_gate();
$f$;

-- Switches the session to p_login acting as authenticated for p_sub, the way
-- the sync service (thsync) and PostgREST (authenticator) do; or back to the
-- superuser that started the test.
create function th972b_test.become(p_login text, p_sub text)
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims',
    pg_catalog.json_build_object('sub', p_sub, 'role', 'authenticated')::text, true);
  if p_login <> pg_catalog.current_setting('th972b.superuser') then
    set local role authenticated;
  end if;
end;
$f$;

grant usage on schema th972b_test to public;
grant execute on all functions in schema th972b_test to public;

-- Catalogue -------------------------------------------------------------------
select th972b_test.ok(
  (select relrowsecurity and relforcerowsecurity from pg_catalog.pg_class
   where oid = 'public.consent_documents'::regclass),
  'consent_documents: row-level security enabled and forced');
select th972b_test.ok(
  (select string_agg(policyname || ':' || cmd || ':' || array_to_string(roles, '+') || ':' || qual,
     ',' order by policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public' and tablename = 'consent_documents') =
  'consent_documents_select_authenticated:SELECT:authenticated:(effective_from <= now())',
  'consent_documents: one select policy for authenticated (documents in effect only), no write policy');
select th972b_test.ok(
  has_table_privilege('authenticated', 'public.consent_documents', 'SELECT')
  and not has_any_column_privilege('authenticated', 'public.consent_documents', 'INSERT')
  and not has_any_column_privilege('authenticated', 'public.consent_documents', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.consent_documents', 'DELETE')
  and not has_table_privilege('authenticated', 'public.consent_documents', 'TRUNCATE')
  and not has_any_column_privilege('anon', 'public.consent_documents', 'SELECT')
  and not has_any_column_privilege('anon', 'public.consent_documents', 'INSERT'),
  'consent_documents: authenticated may only read; anon has no access');
select th972b_test.ok(
  (select count(*) = 20
     and count(distinct purpose) = 10
     and count(distinct locale) = 2
     and bool_and(version = 'v1-draft')
     and bool_and(approved_ref is null)
     and bool_and(not cascades_optional)
     and bool_and(body like '[DRAFT v1-draft - not approved, not for release]%')
     and bool_and(body_sha256 = encode(sha256(convert_to(body, 'UTF8')), 'hex'))
   from public.consent_documents),
  'seed: 20 v1-draft placeholders (10 purposes x en/es), unapproved, marked draft, hashed by the database');
select th972b_test.ok(
  (select count(*) = 20 and bool_and(version = 'v1-draft')
   from public.current_consent_documents())
  and (select count(*) from public.current_consent_documents() where approved_ref is null) = 20,
  'release gate query: every current document is an unapproved draft today');
select th972b_test.ok(
  (select condeferrable and not condeferred and contype = 'u'
   from pg_catalog.pg_constraint
   where conname = 'programme_consents_live_core_key'
     and conrelid = 'public.programme_consents'::regclass),
  'one-live-core key is a unique constraint, deferrable, initially immediate');
select th972b_test.ok(
  (select bool_and(not prosecdef and proconfig = array['search_path=""'])
   from pg_catalog.pg_proc
   where oid in ('public.swap_focus(uuid,uuid)'::regprocedure,
                 'public.supersede_core_consent(uuid,text,text)'::regprocedure,
                 'public.current_consent_documents()'::regprocedure,
                 'public.consent_fill_text()'::regprocedure,
                 'public.consent_documents_guard()'::regprocedure,
                 'public.programme_consents_check_supersede()'::regprocedure,
                 'public.programme_consents_supersede_cascade()'::regprocedure,
                 'public.consent_revoke_only()'::regprocedure)),
  'new and changed functions: security invoker, empty search_path');
select th972b_test.ok(
  has_function_privilege('authenticated', 'public.swap_focus(uuid,uuid)', 'EXECUTE')
  and has_function_privilege('authenticated', 'public.supersede_core_consent(uuid,text,text)', 'EXECUTE')
  and has_function_privilege('authenticated', 'public.current_consent_documents()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.consent_fill_text()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.consent_documents_guard()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.programme_consents_check_supersede()', 'EXECUTE')
  and not has_function_privilege('authenticated', 'public.programme_consents_supersede_cascade()', 'EXECUTE')
  and not exists (
    select 1 from pg_catalog.pg_proc as p
    cross join lateral pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
    where p.oid in ('public.swap_focus(uuid,uuid)'::regprocedure,
                    'public.supersede_core_consent(uuid,text,text)'::regprocedure,
                    'public.current_consent_documents()'::regprocedure,
                    'public.consent_fill_text()'::regprocedure,
                    'public.consent_documents_guard()'::regprocedure,
                    'public.programme_consents_check_supersede()'::regprocedure,
                    'public.programme_consents_supersede_cascade()'::regprocedure)
      and (a.grantee = 0 or a.grantee in ('anon'::regrole, 'thsync'::regrole))),
  'execute: the three callable functions for authenticated only; trigger functions for nobody; none for anon, thsync or PUBLIC');
select th972b_test.ok(
  not has_column_privilege('authenticated', 'public.programme_consents', 'consent_text', 'INSERT')
  and not has_column_privilege('authenticated', 'public.account_consents', 'consent_text', 'INSERT')
  and not has_column_privilege('authenticated', 'public.programme_consents', 'consent_text', 'UPDATE')
  and has_column_privilege('authenticated', 'public.programme_consents', 'locale', 'INSERT')
  and has_column_privilege('authenticated', 'public.account_consents', 'locale', 'INSERT')
  and has_column_privilege('authenticated', 'public.programme_consents', 'superseded_by', 'UPDATE')
  and not has_column_privilege('authenticated', 'public.programme_consents', 'superseded_by', 'INSERT')
  and not has_column_privilege('authenticated', 'public.programme_consents', 'locale', 'UPDATE'),
  'consent columns: clients send locale, never consent_text; superseded_by only on update');

-- Consent release gate ------------------------------------------------------------
-- Each scenario starts from a fully approved catalogue (no rows), adds one
-- failing condition, and is undone afterwards.
select set_config('th972b.approve_all',
  'update public.consent_documents set approved_ref = ''synthetic-approval-all''', true);
select th972b_test.ok(th972b_test.gate_reasons() = 'unapproved'
  and (select count(*) from th972b_test.release_gate()) = 20,
  'gate: the seeded drafts fail the release (20 unapproved documents)');
select th972b_test.ok(
  th972b_test.after(array[current_setting('th972b.approve_all')],
    'select th972b_test.gate_reasons()') = '',
  'gate: a fully approved, complete catalogue passes');
select th972b_test.ok(
  th972b_test.after(array[
    'update public.consent_documents set approved_ref = ''synthetic-approval-all''
     where not (purpose = ''core'' and version = ''v1-draft'')',
    'insert into public.consent_documents (purpose, version, locale, body, effective_from, approved_ref) values
      (''core'', ''v2'', ''en'', ''Synthetic core text'', now(), ''synthetic-approval-02''),
      (''core'', ''v2'', ''es'', ''Synthetic core text (es)'', now(), ''synthetic-approval-02'')'],
    'select th972b_test.gate_reasons() || ''/'' ||
       (select count(*) from public.current_consent_documents() where approved_ref is null)::text
       || ''/'' || (select string_agg(distinct version, '','') from th972b_test.release_gate())')
  = 'unapproved/0/v1-draft',
  'gate: an approved current v2 does not hide the unapproved v1-draft that is still grantable');
select th972b_test.ok(
  th972b_test.after(array[
    current_setting('th972b.approve_all'),
    'insert into public.consent_documents (purpose, version, locale, body, effective_from, approved_ref) values
      (''core'', ''v3'', ''en'', ''Synthetic core text'', now(), ''synthetic-approval-03'')'],
    'select th972b_test.gate_reasons()') = 'missing_locale',
  'gate: a version with en but no es fails');
select th972b_test.ok(
  th972b_test.after(array[
    current_setting('th972b.approve_all'),
    'insert into public.consent_documents (purpose, version, locale, body, effective_from, approved_ref) values
      (''core'', ''v3'', ''en'', ''Synthetic core text'', now() - interval ''1 minute'', ''synthetic-approval-03''),
      (''core'', ''v3'', ''es'', ''Synthetic core text (es)'', now() - interval ''1 minute'', ''synthetic-approval-03'')',
    'update public.consent_documents set retired_at = now() where version = ''v3'' and locale = ''es'''],
    'select th972b_test.gate_reasons()') = 'missing_locale',
  'gate: a version whose es document is retired while en is not fails');
select th972b_test.ok(
  th972b_test.after(array[
    current_setting('th972b.approve_all'),
    'insert into public.consent_documents
       (purpose, version, locale, body, effective_from, approved_ref, cascades_optional) values
      (''core'', ''v4'', ''en'', ''Synthetic core text'', now(), ''synthetic-approval-04'', true),
      (''core'', ''v4'', ''es'', ''Synthetic core text (es)'', now(), ''synthetic-approval-04'', false)'],
    'select th972b_test.gate_reasons()') = 'cascades_optional_differs',
  'gate: locales of one version that disagree on cascades_optional fail');
select th972b_test.ok(
  th972b_test.after(array[
    current_setting('th972b.approve_all'),
    'insert into auth.users (id, email, aud, role) values
      (''00000000-0000-4000-8000-0000009720b9'', ''synthetic-user-b9@example.test'', ''authenticated'', ''authenticated'')',
    'insert into public.enrolments (id, user_id, programme_code)
     values (''00000000-0000-4000-8000-00000972e0b9'', ''00000000-0000-4000-8000-0000009720b9'', ''hw'')',
    'alter table public.programme_consents disable trigger programme_consents_fill_text',
    'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
     values (''00000000-0000-4000-8000-00000972e0b9'', ''core'', ''v1'', ''Synthetic legacy wording'')',
    'alter table public.programme_consents enable trigger programme_consents_fill_text'],
    'select th972b_test.gate_reasons()') = 'consent_without_document',
  'gate: a live programme consent without a document (legacy, no locale) fails');
select th972b_test.ok(
  th972b_test.after(array[
    current_setting('th972b.approve_all'),
    'insert into auth.users (id, email, aud, role) values
      (''00000000-0000-4000-8000-0000009720b9'', ''synthetic-user-b9@example.test'', ''authenticated'', ''authenticated'')',
    'alter table public.account_consents disable trigger account_consents_fill_text',
    'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
     values (''00000000-0000-4000-8000-0000009720b9'', ''essential'', ''v1'', ''Synthetic legacy wording'')',
    'alter table public.account_consents enable trigger account_consents_fill_text'],
    'select th972b_test.gate_reasons()') = 'consent_without_document',
  'gate: a live account consent without a document (legacy, no locale) fails');
select th972b_test.ok(
  th972b_test.after(array['delete from public.consent_documents'],
    'select th972b_test.gate_reasons()') = 'no_documents',
  'gate: an empty document set fails instead of passing vacuously');

-- Synthetic identities and documents --------------------------------------------
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009720b1', 'synthetic-user-b1@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009720b2', 'synthetic-user-b2@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009720b3', 'synthetic-user-b3@example.test',
   'authenticated', 'authenticated');
-- Core versions in order: v1-draft (seed) < v2-test < v3-cascade (marked
-- cascades_optional) < v4-after.
insert into public.consent_documents
  (purpose, version, locale, body, effective_from, retired_at, cascades_optional) values
  ('core', 'v2-test', 'en', 'Synthetic core text v2', now() - interval '40 minutes', null, false),
  ('core', 'v2-test', 'es', 'Synthetic core text v2 (es)', now() - interval '40 minutes', null, false),
  ('core', 'v3-cascade', 'en', 'Synthetic core text v3', now() - interval '30 minutes', null, true),
  -- es takes effect later than en, so a locale move from en to es spans it.
  ('core', 'v3-cascade', 'es', 'Synthetic core text v3 (es)', now() - interval '25 minutes', null, true),
  ('core', 'v4-after', 'en', 'Synthetic core text v4', now() - interval '20 minutes', null, false),
  ('core', 'v0-retired', 'en', 'Synthetic retired core text', now() - interval '2 days',
   now() - interval '1 day', false),
  ('core', 'v9-future', 'en', 'Synthetic future core text', now() + interval '1 day', null, false),
  ('research', 'v5-research', 'en', 'Synthetic research text v5', now(), null, false);
select th972b_test.ok(
  (select string_agg(purpose || ':' || version, ',' order by purpose)
   from public.current_consent_documents() where locale = 'en'
     and purpose in ('core', 'research')) = 'core:v4-after,research:v5-research',
  'current_consent_documents: the latest effective, unretired version per purpose and locale');
select th972b_test.refused(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from, cascades_optional)
   values (''research'', ''v6'', ''en'', ''Synthetic'', now(), true)',
  '23514', '%consent_documents_cascades_core_only_check%', 'cascades_optional is for core documents only');

-- A through the API: enrolments --------------------------------------------------
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b1');
with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-0000009720b1', 'hw') returning id
) select set_config('th972b.a_hw', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, mode)
  values ('00000000-0000-4000-8000-0000009720b1', 'bf', 'quit') returning id
) select set_config('th972b.a_bf', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-0000009720b1', 'st', 'learn_only') returning id
) select set_config('th972b.a_st', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-0000009720b1', 'ca', 'paused') returning id
) select set_config('th972b.a_ca', id::text, true) from i;
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-0000009720b1', 'be', 'learn_only') returning id
) select set_config('th972b.a_be', id::text, true) from i;
select th972b_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L',
  current_setting('th972b.a_be')), 1, 'A: leaves Beacon');

-- The server fills in consent text -------------------------------------------------
select th972b_test.ok(
  (select count(*) = 20 from public.consent_documents where version = 'v1-draft')
  and (select count(*) from public.consent_documents where version = 'v9-future') = 0,
  'A: reads the consent documents in effect, not future ones');
select th972b_test.ok(th972b_test.gate_reasons() like '%role_without_rls_bypass%',
  'gate: run without row-level security bypass it fails (role_without_rls_bypass)');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale, consent_text)
   values (%L, ''core'', ''v1-draft'', ''en'', ''Wording the member never saw'')',
  current_setting('th972b.a_hw')),
  '42501', 'permission denied%', 'A: cannot send consent_text');
select th972b_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, locale, consent_text)
   values (''00000000-0000-4000-8000-0000009720b1'', ''essential'', ''v1-draft'', ''en'', ''Other wording'')',
  '42501', 'permission denied%', 'A: cannot send consent_text for an account consent');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v7-unknown'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document is available for this purpose, version and locale',
  'A: unknown document version refused', 'consent_document_unavailable');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v0-retired'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: retired document version refused', 'consent_document_unavailable');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v9-future'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: not yet effective document version refused', 'consent_document_unavailable');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version)
   values (%L, ''core'', ''v1-draft'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: a grant without a locale is refused', 'consent_document_unavailable');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v5-research'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: another purpose''s document version refused', 'consent_document_unavailable');
select th972b_test.affects(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v1-draft'', ''es'')',
  current_setting('th972b.a_hw')), 1, 'A: grants core on Heartwise (v1-draft, es)');
select th972b_test.ok(
  (select c.consent_text = d.body and c.locale = 'es' and c.consent_version = 'v1-draft'
   from public.programme_consents as c
   join public.consent_documents as d
     on d.purpose = c.purpose and d.version = c.consent_version and d.locale = c.locale
   where c.enrolment_id = current_setting('th972b.a_hw')::uuid and c.purpose = 'core'),
  'A: the stored core text is exactly the document body');
insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
values
  (current_setting('th972b.a_hw')::uuid, 'reminders', null, 'v1-draft', 'en'),
  (current_setting('th972b.a_hw')::uuid, 'research', null, 'v5-research', 'en'),
  (current_setting('th972b.a_hw')::uuid, 'share_care_team', 'synthetic-connection-b1', 'v1-draft', 'en');
select th972b_test.ok(
  (select bool_and(c.consent_text = d.body) and count(*) = 4
   from public.programme_consents as c
   join public.consent_documents as d
     on d.purpose = c.purpose and d.version = c.consent_version and d.locale = c.locale
   where c.enrolment_id = current_setting('th972b.a_hw')::uuid),
  'A: every stored programme consent text equals its document body');
select th972b_test.affects(
  'insert into public.account_consents (user_id, purpose, consent_version, locale)
   values (''00000000-0000-4000-8000-0000009720b1'', ''essential'', ''v1-draft'', ''en'')',
  1, 'A: grants an account consent');
select th972b_test.ok(
  (select c.consent_text = d.body
   from public.account_consents as c
   join public.consent_documents as d
     on d.purpose = c.purpose and d.version = c.consent_version and d.locale = c.locale
   where c.user_id = '00000000-0000-4000-8000-0000009720b1'),
  'A: the stored account consent text equals its document body');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''reminders'', ''v1-draft'', ''en'')',
  current_setting('th972b.a_hw')),
  '23505', '%programme_consents_live_key%', 'A: a second live optional consent is refused (partial index)');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v1-draft'', ''en'')',
  current_setting('th972b.a_hw')),
  '23505', '%programme_consents_live_core_key%', 'A: a second live core consent is refused (deferrable key, checked per statement)');
select th972b_test.refused(
  'insert into public.consent_documents (purpose, version, locale, body, effective_from)
   values (''core'', ''v8'', ''en'', ''Synthetic'', now())',
  '42501', 'permission denied%', 'A: cannot add a consent document');
select th972b_test.refused(
  'update public.consent_documents set approved_ref = ''synthetic'' where version = ''v1-draft''',
  '42501', 'permission denied%', 'A: cannot approve a consent document');
select th972b_test.refused(
  'delete from public.consent_documents where version = ''v1-draft''',
  '42501', 'permission denied%', 'A: cannot delete a consent document');

-- Documents are fixed once written (as a privileged role) ----------------------------
select th972b_test.become(current_setting('th972b.superuser'), '');
select th972b_test.refused(
  'update public.consent_documents set body = ''Changed'' where purpose = ''core'' and version = ''v2-test''',
  'TH015', 'Consent documents are immutable; publish a new version',
  'superuser: a document body cannot change', 'consent_document_immutable');
select th972b_test.refused(
  'update public.consent_documents set version = ''v2-other'' where purpose = ''core'' and version = ''v2-test''',
  'TH015', 'Consent documents are immutable%', 'superuser: a document version cannot change',
  'consent_document_immutable');
select th972b_test.affects(
  'update public.consent_documents set body_sha256 = repeat(''a'', 64)
   where purpose = ''core'' and version = ''v2-test'' and locale = ''en''',
  1, 'superuser: writes body_sha256');
select th972b_test.ok(
  (select body_sha256 = encode(sha256(convert_to(body, 'UTF8')), 'hex') from public.consent_documents
   where purpose = 'core' and version = 'v2-test' and locale = 'en'),
  'superuser: body_sha256 is recomputed by the database, not taken from the writer');
select th972b_test.affects(
  'update public.consent_documents set approved_ref = ''synthetic-approval-01''
   where purpose = ''reminders'' and version = ''v1-draft'' and locale = ''en''',
  1, 'superuser: records an approval reference');
select th972b_test.ok(
  (select count(*) from public.current_consent_documents() where approved_ref is null)
  = (select count(*) from public.current_consent_documents()) - 1,
  'an approved current document drops out of the unapproved list');
select th972b_test.refused(
  'update public.consent_documents set approved_ref = ''synthetic-approval-02''
   where purpose = ''reminders'' and version = ''v1-draft'' and locale = ''en''',
  'TH015', 'Consent documents are immutable%', 'superuser: an approval reference cannot be replaced',
  'consent_document_immutable');
select th972b_test.refused(
  'update public.consent_documents set approved_ref = null
   where purpose = ''reminders'' and version = ''v1-draft'' and locale = ''en''',
  'TH015', 'Consent documents are immutable%', 'superuser: an approval reference cannot be removed',
  'consent_document_immutable');
select th972b_test.refused(
  'update public.consent_documents set cascades_optional = true
   where purpose = ''core'' and version = ''v1-draft'' and locale = ''es''',
  'TH015', 'Consent documents are immutable%',
  'superuser: cascades_optional is fixed once a consent references the document', 'consent_document_immutable');
select th972b_test.refused(
  'update public.consent_documents set effective_from = effective_from - interval ''1 day''
   where purpose = ''core'' and version = ''v1-draft'' and locale = ''es''',
  'TH015', 'Consent documents are immutable%',
  'superuser: effective_from is fixed once a programme consent references the document', 'consent_document_immutable');
select th972b_test.refused(
  'update public.consent_documents set effective_from = effective_from - interval ''1 day''
   where purpose = ''essential'' and version = ''v1-draft'' and locale = ''en''',
  'TH015', 'Consent documents are immutable%',
  'superuser: effective_from is fixed once an account consent references the document', 'consent_document_immutable');
select th972b_test.ok(
  th972b_test.after(array[
    'update public.consent_documents set retired_at = now()
     where purpose = ''core'' and version = ''v1-draft'' and locale = ''es'''],
    'select retired_at::text from public.consent_documents
     where purpose = ''core'' and version = ''v1-draft'' and locale = ''es''') is not null,
  'superuser: a referenced document can still be retired');
select th972b_test.ok(
  th972b_test.after(array[
    'update public.consent_documents set effective_from = now() + interval ''2 days'', cascades_optional = true
     where purpose = ''core'' and version = ''v9-future'''],
    'select cascades_optional::text from public.consent_documents
     where purpose = ''core'' and version = ''v9-future''') = 'true',
  'superuser: an unreferenced document''s effective_from and cascades_optional can still change');
select th972b_test.refused(
  'delete from public.consent_documents where purpose = ''core'' and version = ''v1-draft'' and locale = ''es''',
  '23503', '%programme_consents_document_fkey%', 'superuser: a referenced document cannot be deleted');
with i as (
  insert into public.programme_consents (enrolment_id, purpose, consent_version, locale, consent_text)
  values (current_setting('th972b.a_ca')::uuid, 'core', 'v1-draft', 'en', 'Wording from a privileged writer')
  returning id, consent_text
) select th972b_test.ok(
  (select i.consent_text = d.body from i join public.consent_documents as d
   on d.purpose = 'core' and d.version = 'v1-draft' and d.locale = 'en'),
  'superuser: even a privileged insert stores the document body, not the supplied text') from i;
delete from public.programme_consents where enrolment_id = current_setting('th972b.a_ca')::uuid;

-- Supersession ----------------------------------------------------------------------
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b1');
select set_config('th972b.hw_core_old', (select id::text from public.programme_consents
  where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose = 'core'), true);
select set_config('th972b.supersede', (
  select jsonb_agg(to_jsonb(s) - 'ordinality' order by s.ordinality)::text
  from public.supersede_core_consent(current_setting('th972b.a_hw')::uuid, 'v2-test', 'en')
    with ordinality as s), true);
select th972b_test.ok(
  jsonb_array_length(current_setting('th972b.supersede')::jsonb) = 2
  and (select r0 ->> 'id' = current_setting('th972b.hw_core_old')
         and r0 ->> 'revoked_at' is not null
         and r0 ->> 'superseded_by' = r1 ->> 'id'
         and r1 ->> 'revoked_at' is null and r1 ->> 'superseded_by' is null
         and r1 ->> 'purpose' = 'core' and r1 ->> 'consent_version' = 'v2-test'
         and r1 ->> 'locale' = 'en' and r1 ->> 'consent_text' = 'Synthetic core text v2'
       from (select current_setting('th972b.supersede')::jsonb -> 0 as r0,
                    current_setting('th972b.supersede')::jsonb -> 1 as r1) as r),
  'A: supersede returns the old row (revoked, superseded_by = new id), then the new live row with the document text');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose = 'core') = 2
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose = 'core'
         and revoked_at is null) = 1,
  'A: history keeps both core rows; one is live');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose <> 'core'
     and revoked_at is null) = 3
  and public.has_consent(current_setting('th972b.a_hw')::uuid, 'core')
  and public.has_consent(current_setting('th972b.a_hw')::uuid, 'reminders')
  and public.has_consent(current_setting('th972b.a_hw')::uuid, 'research')
  and public.has_consent(current_setting('th972b.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-b1'),
  'A: supersession does not cascade: reminders, research and sharing stay live and honoured');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v1-draft'', ''en'')',
  current_setting('th972b.a_hw')),
  '23505', '%programme_consents_live_core_key%', 'A: after a supersession the live-core key is immediate again');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v2-test'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH014', 'The core consent is already on this version or a later one',
  'A: superseding to the same version and locale is refused', 'consent_version_unchanged');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v1-draft'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH014', 'The core consent is already on this version or a later one',
  'A: superseding to an older version (downgrade) is refused', 'consent_version_unchanged');
select th972b_test.refused(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = %L
   where enrolment_id = %L and purpose = ''core'' and revoked_at is null',
  current_setting('th972b.hw_core_old'), current_setting('th972b.a_hw')),
  'TH003', 'Consent records are immutable',
  'A: superseded_by cannot name the same enrolment''s revoked history row', 'consent_immutable');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v404'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: superseding to an unknown version is refused',
  'consent_document_unavailable');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v0-retired'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: superseding to a retired version is refused',
  'consent_document_unavailable');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v5-research'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: superseding to a non-core document is refused',
  'consent_document_unavailable');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v4-after'', ''es'')',
  current_setting('th972b.a_hw')),
  'TH011', 'No consent document%', 'A: superseding to a locale the version lacks is refused',
  'consent_document_unavailable');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v2-test'', ''en'')',
  current_setting('th972b.a_be')),
  'TH005', 'The programme has been left', 'A: no supersession on a left enrolment', 'enrolment_left');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v2-test'', ''en'')',
  current_setting('th972b.a_ca')),
  'TH004', 'A live core consent is required', 'A: no supersession without a live core consent',
  'consent_requires_core');
select th972b_test.refused(
  'select * from public.supersede_core_consent(gen_random_uuid(), ''v2-test'', ''en'')',
  'TH012', 'Enrolment not found', 'A: no supersession on an unknown enrolment', 'enrolment_not_found');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_hw')::uuid) = 5,
  'A: the refused supersessions added nothing');
select th972b_test.ok(
  (select string_agg(consent_version || ':' || locale, ',')
   from public.supersede_core_consent(current_setting('th972b.a_hw')::uuid, 'v2-test', 'es'))
    = 'v2-test:en,v2-test:es',
  'A: moving to the same version in another locale is allowed');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose <> 'core'
     and revoked_at is null) = 3,
  'A: the locale move keeps the optional consents');

-- A document marked cascades_optional also revokes the optional consents.
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th972b.a_bf')::uuid, 'core', 'v1-draft', 'en');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th972b.a_bf')::uuid, 'reminders', 'v1-draft', 'en');
select th972b_test.ok(
  (select count(*) = 2 from public.supersede_core_consent(
     current_setting('th972b.a_bf')::uuid, 'v3-cascade', 'en')),
  'A: supersedes BreatheFree core to a cascades_optional version');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_bf')::uuid and purpose <> 'core'
     and revoked_at is null) = 0
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th972b.a_bf')::uuid and purpose = 'core'
         and revoked_at is null and consent_version = 'v3-cascade') = 1
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th972b.a_bf')::uuid and purpose = 'core'
         and superseded_by is not null) = 1
  and not public.has_consent(current_setting('th972b.a_bf')::uuid, 'reminders'),
  'A: with cascades_optional the optional consents are revoked; core moves to the new version');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th972b.a_bf')::uuid, 'reminders', 'v1-draft', 'en');
select th972b_test.ok(
  (select string_agg(consent_version || ':' || locale, ',')
   from public.supersede_core_consent(current_setting('th972b.a_bf')::uuid, 'v3-cascade', 'es'))
    = 'v3-cascade:en,v3-cascade:es',
  'A: moves BreatheFree core from v3-cascade en to v3-cascade es');
select th972b_test.ok(
  public.has_consent(current_setting('th972b.a_bf')::uuid, 'reminders'),
  'A: a locale-only move never cascades, even to a cascades_optional document');

-- A plain revocation cannot skip the cascade by naming a superseded_by.
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th972b.a_st')::uuid, 'core', 'v1-draft', 'en');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th972b.a_st')::uuid, 'research', 'v5-research', 'en');
select th972b_test.refused(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = (
     select id from public.programme_consents where enrolment_id = %L and purpose = ''core''
       and revoked_at is null)
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th972b.a_hw'), current_setting('th972b.a_st')),
  'TH003', 'Consent records are immutable',
  'A: superseded_by cannot name another enrolment''s live core consent', 'consent_immutable');
select th972b_test.refused(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = %L
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th972b.hw_core_old'), current_setting('th972b.a_st')),
  'TH003', 'Consent records are immutable',
  'A: superseded_by cannot name another enrolment''s (revoked) core row', 'consent_immutable');
select th972b_test.refused(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = id
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th972b.a_st')),
  'TH003', 'Consent records are immutable', 'A: superseded_by cannot name the row itself',
  'consent_immutable');
select th972b_test.refused(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = (
     select id from public.programme_consents where enrolment_id = %L and purpose = ''research'')
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th972b.a_st'), current_setting('th972b.a_st')),
  'TH003', 'Consent records are immutable', 'A: superseded_by cannot name an optional consent',
  'consent_immutable');
select th972b_test.refused(format(
  'update public.programme_consents set superseded_by = (
     select id from public.programme_consents where enrolment_id = %L and purpose = ''core''
       and revoked_at is null)
   where id = %L',
  current_setting('th972b.a_hw'), current_setting('th972b.hw_core_old')),
  'TH002', 'Consent is already revoked', 'A: a revoked row cannot gain a superseded_by later',
  'consent_already_revoked');
select th972b_test.affects(format(
  'update public.programme_consents set revoked_at = now()
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th972b.a_st')), 1, 'A: revokes Steady core (the member''s own revocation)');
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.a_st')::uuid and revoked_at is null) = 0,
  'A: the member''s own core revocation still cascades');

-- Focus swap -------------------------------------------------------------------------
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',' order by programme_code)
   from public.enrolments) = 'be:left,bf:focus,ca:paused,hw:focus,st:learn_only',
  'A: before swapping, Heartwise and BreatheFree are in focus');
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',')
   from public.swap_focus(current_setting('th972b.a_hw')::uuid,
                          current_setting('th972b.a_st')::uuid)) = 'hw:paused,st:focus',
  'A: swap_focus returns the demoted row (paused, data kept) then the promoted row (focus)');
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',' order by programme_code)
   from public.enrolments) = 'be:left,bf:focus,ca:paused,hw:paused,st:focus',
  'A: the swap is stored; still two in focus');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_ca'), current_setting('th972b.a_hw')),
  'TH013', 'A swap needs one programme in focus and another not in focus',
  'A: demoting a programme that is not in focus is refused', 'focus_swap_invalid');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_bf'), current_setting('th972b.a_st')),
  'TH013', 'A swap needs%', 'A: promoting a programme already in focus is refused', 'focus_swap_invalid');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_bf'), current_setting('th972b.a_bf')),
  'TH013', 'A swap needs%', 'A: swapping a programme with itself is refused', 'focus_swap_invalid');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, null)', current_setting('th972b.a_bf')),
  'TH013', 'A swap needs%', 'A: a swap without a programme to promote is refused', 'focus_swap_invalid');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_bf'), current_setting('th972b.a_be')),
  'TH005', 'The programme has been left', 'A: promoting a left programme is refused', 'enrolment_left');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, gen_random_uuid())', current_setting('th972b.a_bf')),
  'TH012', 'Enrolment not found', 'A: promoting an unknown enrolment is refused', 'enrolment_not_found');
-- Atomicity and the cap: a third focus programme is inserted earlier in the
-- same transaction (pending until the cap is checked). swap_focus checks the
-- cap before returning, so the call fails with TH001, and everything in the
-- failed statement, the swap's own demote and promote included, is undone.
select th972b_test.refused(format(
  'select th972b_test.run(array[%L, %L])',
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-0000009720b1'', ''nu'')',
  format('select * from public.swap_focus(%L, %L)',
    current_setting('th972b.a_bf'), current_setting('th972b.a_hw'))),
  'TH001', 'At most two programmes can be in focus',
  'A: swap_focus raises TH001 when the transaction would end with three programmes in focus', 'focus_cap_reached');
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',' order by programme_code)
   from public.enrolments) = 'be:left,bf:focus,ca:paused,hw:paused,st:focus',
  'A: after the failed swap both rows are unchanged (BreatheFree still focus, Heartwise still paused)');
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',')
   from public.swap_focus(current_setting('th972b.a_bf')::uuid,
                          current_setting('th972b.a_ca')::uuid)) = 'bf:paused,ca:focus',
  'A: a paused programme can be promoted');

-- Cascades over intermediate versions, legacy rows and hand-rolled supersessions --
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b3');
with i as (
  insert into public.enrolments (user_id, programme_code, status) values
    ('00000000-0000-4000-8000-0000009720b3', 'sd', 'learn_only'),
    ('00000000-0000-4000-8000-0000009720b3', 'ea', 'learn_only'),
    ('00000000-0000-4000-8000-0000009720b3', 'ck', 'learn_only'),
    ('00000000-0000-4000-8000-0000009720b3', 're', 'learn_only')
  returning id, programme_code
) select set_config('th972b.d_' || programme_code, id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  (current_setting('th972b.d_sd')::uuid, 'core', 'v2-test', 'en'),
  (current_setting('th972b.d_re')::uuid, 'core', 'v2-test', 'en');
-- Rows stored before consent documents existed: no locale, own text.
select th972b_test.become(current_setting('th972b.superuser'), '');
alter table public.programme_consents disable trigger programme_consents_fill_text;
insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text) values
  (current_setting('th972b.d_ea')::uuid, 'core', 'v1', 'Synthetic legacy core wording'),
  (current_setting('th972b.d_ck')::uuid, 'core', 'v1', 'Synthetic legacy core wording');
alter table public.programme_consents enable trigger programme_consents_fill_text;
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b3');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  (current_setting('th972b.d_sd')::uuid, 'research', 'v5-research', 'en'),
  (current_setting('th972b.d_ea')::uuid, 'research', 'v5-research', 'en'),
  (current_setting('th972b.d_ck')::uuid, 'research', 'v5-research', 'en'),
  (current_setting('th972b.d_re')::uuid, 'research', 'v5-research', 'en');
select th972b_test.ok(
  (select count(*) = 2 from public.supersede_core_consent(
     current_setting('th972b.d_sd')::uuid, 'v4-after', 'en')),
  'D: supersedes Stride core from v2-test straight to v4-after');
select th972b_test.ok(
  not public.has_consent(current_setting('th972b.d_sd')::uuid, 'research')
  and public.has_consent(current_setting('th972b.d_sd')::uuid, 'core'),
  'D: superseding from v2 straight to v4 passes the cascades_optional v3, so optional consents are revoked');
select th972b_test.ok(
  (select count(*) = 2 from public.supersede_core_consent(
     current_setting('th972b.d_ea')::uuid, 'v2-test', 'en')),
  'D: supersedes a legacy core row (no locale) to v2-test');
select th972b_test.ok(
  public.has_consent(current_setting('th972b.d_ea')::uuid, 'research'),
  'D: a legacy row (no locale) supersedes forward; no cascades_optional version up to v2, so no cascade');
select th972b_test.ok(
  (select count(*) = 2 from public.supersede_core_consent(
     current_setting('th972b.d_ck')::uuid, 'v4-after', 'en')),
  'D: supersedes a legacy core row (no locale) to v4-after');
select th972b_test.ok(
  not public.has_consent(current_setting('th972b.d_ck')::uuid, 'research'),
  'D: a legacy row superseded to v4 cascades, because v3 (cascades_optional) lies before it');
-- The same rules without the function: revoke, insert and superseded_by
-- written directly by the caller in one transaction.
select th972b_test.run(array[
  'set constraints public.programme_consents_live_core_key deferred',
  format('insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
          values (%L, ''core'', ''v4-after'', ''en'')', current_setting('th972b.d_re')),
  format('update public.programme_consents set revoked_at = now(), superseded_by = (
            select id from public.programme_consents where enrolment_id = %L and purpose = ''core''
              and consent_version = ''v4-after'')
          where enrolment_id = %L and purpose = ''core'' and consent_version = ''v2-test''',
         current_setting('th972b.d_re'), current_setting('th972b.d_re')),
  'set constraints public.programme_consents_live_core_key immediate']);
select th972b_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th972b.d_re')::uuid and purpose = 'core'
     and superseded_by is not null) = 1
  and public.has_consent(current_setting('th972b.d_re')::uuid, 'core')
  and not public.has_consent(current_setting('th972b.d_re')::uuid, 'research'),
  'D: a hand-written supersession past v3 cascades too (rules enforced by triggers)');
select th972b_test.refused(format(
  'select th972b_test.run(array[%L, %L, %L])',
  'set constraints public.programme_consents_live_core_key deferred',
  format('insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
          values (%L, ''core'', ''v2-test'', ''en'')', current_setting('th972b.d_re')),
  format('update public.programme_consents set revoked_at = now(), superseded_by = (
            select id from public.programme_consents where enrolment_id = %L and purpose = ''core''
              and consent_version = ''v2-test'' and revoked_at is null)
          where enrolment_id = %L and purpose = ''core'' and consent_version = ''v4-after''',
         current_setting('th972b.d_re'), current_setting('th972b.d_re'))),
  'TH014', 'The core consent is already on this version or a later one',
  'D: a hand-written downgrade is refused too', 'consent_version_unchanged');

-- Member-only access ---------------------------------------------------------------
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b2');
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-0000009720b2', 'hw', 'learn_only') returning id
) select set_config('th972b.c_hw', id::text, true) from i;
select th972b_test.ok(
  (select count(*) from public.enrolments) = 1
  and (select count(*) from public.programme_consents) = 0,
  'C: sees only C''s own enrolment and no consents of A');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_st'), current_setting('th972b.c_hw')),
  'TH012', 'Enrolment not found', 'C: cannot demote A''s enrolment', 'enrolment_not_found');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v3-cascade'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH012', 'Enrolment not found', 'C: cannot supersede A''s core consent', 'enrolment_not_found');
select th972b_test.affects(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = null
   where enrolment_id = %L', current_setting('th972b.a_hw')),
  0, 'C: cannot touch A''s consent rows');
select th972b_test.ok(
  (select count(*) = 20 from public.consent_documents where version = 'v1-draft'),
  'C: reads the shared consent documents');

-- anon (no token) ---------------------------------------------------------------
select th972b_test.become(current_setting('th972b.superuser'), '');
set local role anon;
select th972b_test.refused('select count(*) from public.consent_documents',
  '42501', 'permission denied%', 'anon: cannot read consent documents');
select th972b_test.refused('select * from public.current_consent_documents()',
  '42501', 'permission denied%', 'anon: cannot execute current_consent_documents');
select th972b_test.refused(
  'select * from public.swap_focus(gen_random_uuid(), gen_random_uuid())',
  '42501', 'permission denied%', 'anon: cannot execute swap_focus');
select th972b_test.refused(
  'select * from public.supersede_core_consent(gen_random_uuid(), ''v1-draft'', ''en'')',
  '42501', 'permission denied%', 'anon: cannot execute supersede_core_consent');
reset role;

-- Sync service session (thsync) is refused -------------------------------------------
select th972b_test.become('thsync', '00000000-0000-4000-8000-0000009720b1');
select th972b_test.ok(session_user = 'thsync' and public.sync_writer_session()
  and auth.uid() = '00000000-0000-4000-8000-0000009720b1',
  'sync session: logged in as thsync with A''s claims');
select th972b_test.refused(format(
  'select * from public.swap_focus(%L, %L)',
  current_setting('th972b.a_st'), current_setting('th972b.a_hw')),
  'TH010', 'The sync service writes only sync tables',
  'A sync: swap_focus refuses the sync session', 'sync_session_refused');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v3-cascade'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH010', 'The sync service writes only sync tables',
  'A sync: supersede_core_consent refuses the sync session', 'sync_session_refused');
select th972b_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''screen_time'', ''v1-draft'', ''en'')',
  current_setting('th972b.a_hw')),
  '42501', '%row-level security%', 'A sync: cannot grant a consent');
select th972b_test.affects(format(
  'update public.programme_consents set revoked_at = now(), superseded_by = null
   where enrolment_id = %L and revoked_at is null', current_setting('th972b.a_hw')),
  0, 'A sync: cannot revoke or supersede a consent (no row qualifies)');
select th972b_test.ok(
  (select count(*) from public.consent_documents) = 27
  and (select count(*) from public.current_consent_documents()) = 20,
  'A sync: reads consent documents');

-- Nothing changed by the refused calls ------------------------------------------------
select th972b_test.become(current_setting('th972b.superuser'), '');
select th972b_test.ok(
  (select string_agg(programme_code || ':' || status, ',' order by programme_code)
   from public.enrolments where user_id = '00000000-0000-4000-8000-0000009720b1')
    = 'be:left,bf:paused,ca:focus,hw:paused,st:focus'
  and (select status from public.enrolments where id = current_setting('th972b.c_hw')::uuid)
    = 'learn_only'
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th972b.a_hw')::uuid and revoked_at is null) = 4
  and (select consent_version from public.programme_consents
       where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose = 'core'
         and revoked_at is null) = 'v2-test'
  and (select locale from public.programme_consents
       where enrolment_id = current_setting('th972b.a_hw')::uuid and purpose = 'core'
         and revoked_at is null) = 'es',
  'refused calls by C and by the sync session changed no enrolment or consent');

-- Deletion keeps working with supersession history -------------------------------------
select th972b_test.become('authenticator', '00000000-0000-4000-8000-0000009720b1');
select th972b_test.ok(public.begin_account_deletion('DELETE'), 'A: deletion barrier set');
select th972b_test.refused(format(
  'select * from public.supersede_core_consent(%L, ''v3-cascade'', ''en'')',
  current_setting('th972b.a_hw')),
  'TH006', 'Account deletion has started', 'A: no supersession once deletion has started',
  'deletion_in_progress');
select th972b_test.affects(format(
  'delete from public.enrolments where id = %L', current_setting('th972b.a_bf')),
  1, 'A: delete-now on an enrolment with a superseded core row');
select set_config('th972b.a_receipt', public.delete_my_app_data('DELETE')::text, true);
select th972b_test.ok(
  (current_setting('th972b.a_receipt')::jsonb ->> 'enrolments')::int = 4
  and (current_setting('th972b.a_receipt')::jsonb ->> 'programme_consents')::int = 8
  and (current_setting('th972b.a_receipt')::jsonb ->> 'account_consents')::int = 1,
  'A: delete_my_app_data removes the remaining enrolments and consents, superseded history included');
select th972b_test.become(current_setting('th972b.superuser'), '');
select th972b_test.ok(
  (select count(*) from public.programme_consents as c
   where c.enrolment_id in (current_setting('th972b.a_hw')::uuid, current_setting('th972b.a_bf')::uuid,
     current_setting('th972b.a_st')::uuid, current_setting('th972b.a_ca')::uuid,
     current_setting('th972b.a_be')::uuid)) = 0
  and (select count(*) from public.consent_documents) = 28,
  'A''s consents are gone; the consent documents remain');

select 'TH972B_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Enrolment and consent follow-up check failed: $1" >&2
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

# Consent documents: forced RLS, read-only for authenticated, nothing for anon.
grep -Fq 'alter table public.consent_documents enable row level security;' <<<"$sql" ||
  fail 'consent_documents must enable row level security'
grep -Fq 'alter table public.consent_documents force row level security;' <<<"$sql" ||
  fail 'consent_documents must force row level security'
grep -Fq 'revoke all on table public.consent_documents from anon, authenticated;' <<<"$sql" ||
  fail 'consent_documents must revoke the default table privileges'
if ! { [[ "$(grep -Ec '^grant [a-z, ()_]+ on table public\.consent_documents ' <<<"$sql")" -eq 1 ]] &&
  grep -Eq '^grant select on table public\.consent_documents to authenticated;$' <<<"$sql"; }; then
  fail 'consent_documents: the only grant is select to authenticated'
fi
if ! { [[ "$(grep -Ec '^create policy ' <<<"$sql")" -eq 1 ]] &&
  grep -A2 '^create policy "consent_documents_select_authenticated"' <<<"$sql" |
  grep -Fq 'on public.consent_documents for select'; }; then
  fail 'this migration creates exactly one policy: the consent_documents select policy'
fi
if grep -Eq '^(drop|alter) policy ' <<<"$sql"; then
  fail 'this migration must not change existing policies'
fi

# Seeds are drafts only.
seed=$(sed -n '/^insert into public.consent_documents/,/;$/p' "$migration")
[[ -n "$seed" ]] || fail 'no consent_documents seed'
grep -Fq "'v1-draft'" <<<"$seed" || fail 'the seed version must be v1-draft'
grep -Fq "[DRAFT v1-draft - not approved, not for release]" <<<"$seed" ||
  fail 'seeded bodies must say they are unapproved drafts'
if grep -Eq 'approved_ref|cascades_optional' <<<"$seed"; then
  fail 'the seed must leave approved_ref null and cascades_optional false'
fi

# The client never supplies consent text.
grep -Eq '^revoke insert \(consent_text\) on table public\.programme_consents from authenticated;$' <<<"$sql" ||
  fail 'insert on programme_consents.consent_text must be revoked from authenticated'
grep -Eq '^revoke insert \(consent_text\) on table public\.account_consents from authenticated;$' <<<"$sql" ||
  fail 'insert on account_consents.consent_text must be revoked from authenticated'
if grep -Eiq '^grant [^;]*consent_text' <<<"$sql"; then
  fail 'consent_text must not be granted to anyone'
fi
fill=$(body_of consent_fill_text)
grep -Fq 'new.consent_text = document_body;' <<<"$fill" ||
  fail 'consent_fill_text must set consent_text from the document'
for t in programme_consents account_consents; do
  grep -A2 "^create trigger ${t}_fill_text\$" <<<"$sql" |
    grep -Fq "before insert on public.$t" || fail "$t needs the before-insert text trigger"
done

# Supersession: no cascade unless the document says so; text from the document.
grep -A6 '^create trigger programme_consents_revoke_with_core$' <<<"$sql" |
  grep -Fq 'and new.superseded_by is null' ||
  fail 'the revoke-with-core cascade must skip superseded rows'
supersede=$(body_of supersede_core_consent)
if ! { grep -Eq '^create function public\.supersede_core_consent\($' <<<"$supersede" &&
  [[ "$(sed -n '2,4p' <<<"$supersede" | tr -d ' \n')" == 'p_enrolmentuuid,p_versiontext,p_localetext' ]]; }; then
  fail 'supersede_core_consent takes (p_enrolment uuid, p_version text, p_locale text) only'
fi
grep -Fq 'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)' <<<"$supersede" ||
  fail 'supersede_core_consent must insert without consent_text (the trigger fills it)'
if grep -Fq 'cascades_optional' <<<"$supersede"; then
  fail 'supersede_core_consent leaves the cascade decision to programme_consents_supersede_cascade'
fi
# Ordering and cascade rules live in triggers, so every write path gets them.
check=$(body_of programme_consents_check_supersede)
grep -Fq 'if old_effective is null or new_effective is null or new_effective <= old_effective then' <<<"$check" ||
  fail 'programme_consents_check_supersede must refuse a replacement that is not later'
cascade=$(body_of programme_consents_supersede_cascade)
grep -Fq 'if old.locale is not null and replacement.consent_version = old.consent_version then' <<<"$cascade" ||
  fail 'a locale-only move must never cascade'
grep -Fq "old_effective := '-infinity';" <<<"$cascade" ||
  fail 'a null-locale old row counts as older than every document'
if ! { grep -Fq 'and d.effective_from > old_effective' <<<"$cascade" &&
  grep -Fq 'and d.effective_from <= new_effective' <<<"$cascade" &&
  grep -Fq 'and d.locale = replacement.locale' <<<"$cascade"; }; then
  fail 'the cascade looks at every flagged core document for the new locale between the two versions'
fi
grep -A3 '^create trigger programme_consents_supersede_cascade$' <<<"$sql" |
  grep -Fq 'after update of superseded_by on public.programme_consents' ||
  fail 'programme_consents_supersede_cascade must run after every update that sets superseded_by'

# The documented release gate is the block the SQL test runs.
gate=$(release_gate_sql)
for reason in role_without_rls_bypass no_documents unapproved missing_locale \
  cascades_optional_differs consent_without_document; do
  grep -Fq "'$reason'" <<<"$gate" || fail "the release gate in $contract must report $reason"
done
if ! { grep -Fq 'set constraints public.programme_consents_live_core_key deferred;' <<<"$supersede" &&
  grep -Fq 'set constraints public.programme_consents_live_core_key immediate;' <<<"$supersede"; }; then
  fail 'supersede_core_consent must defer the live-core key and restore it before returning'
fi
grep -Eq '^  unique \(live_core_enrolment_id\) deferrable initially immediate;$' <<<"$sql" ||
  fail 'the live-core key must be deferrable initially immediate'

# Focus swap: one function, both updates, cap checked before returning.
swap=$(body_of swap_focus)
if ! { grep -Fq "update public.enrolments set status = 'paused'" <<<"$swap" &&
  grep -Fq "update public.enrolments set status = 'focus'" <<<"$swap"; }; then
  fail 'swap_focus must demote to paused and promote to focus'
fi
grep -Fq 'set constraints public.enrolments_focus_cap immediate;' <<<"$swap" ||
  fail 'swap_focus must check the focus cap before it returns'
if grep -Eiq '^ *exception' <<<"$swap$supersede"; then
  fail 'swap_focus and supersede_core_consent must not catch errors (a partial change could survive)'
fi

# Function hygiene.
functions=$(grep -Ec '^create (or replace )?function ' <<<"$sql")
pinned=$(grep -Ec "^set search_path = ''$" <<<"$sql")
[[ "$functions" -eq 8 && "$pinned" -eq 8 ]] ||
  fail "expected 8 functions, all with search_path = '' (got $functions, $pinned)"
if grep -Eq '^security definer$' <<<"$sql"; then
  fail 'no function in this migration may be security definer'
fi
for fn in swap_focus supersede_core_consent current_consent_documents; do
  grep -Fq 'security invoker' <<<"$(body_of "$fn")" || fail "$fn must be security invoker"
  grep -Eq "^revoke all on function public\\.$fn\\(" <<<"$sql" || fail "$fn: revoke all first"
done
for fn in consent_fill_text consent_documents_guard programme_consents_check_supersede \
  programme_consents_supersede_cascade consent_revoke_only; do
  grep -Eq "^revoke all on function public\\.$fn\\(\\)$" <<<"$sql" || fail "$fn: revoke all"
  if grep -Eq "^grant execute on function public\\.$fn\\(" <<<"$sql"; then
    fail "$fn is a trigger function; nobody executes it directly"
  fi
done
[[ "$(grep -Ec '^grant execute on function ' <<<"$sql")" -eq 3 ]] ||
  fail 'only swap_focus, supersede_core_consent and current_consent_documents are executable'
if grep -Eiq 'grant .* to (.*[^a-z_])?(anon|thsync|public)([^a-z_]|$)' <<<"$sql"; then
  fail 'nothing is granted to anon, thsync or PUBLIC'
fi
if grep -Eiq 'disable row level security|no force row level security|bypassrls|(create|alter|drop) role|owner to' <<<"$sql"; then
  fail 'migration must not weaken RLS or change roles'
fi
if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' <<<"$sql"; then
  fail 'migration must not contain credentials or service-role use'
fi

# Registry consistency: every raise in this migration uses a registered code
# with its registered hint and message, and its row names the raising function.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
fn_re='^create (or replace )?function public\.([a-z_]+)\('
raise_re="errcode = '(TH[0-9]{3})', message = '([^']+)', hint = '([a-z_]+)';"
expected_raises=21
checked=0
current_fn=''
while IFS= read -r line; do
  if [[ "$line" =~ $fn_re ]]; then
    current_fn="${BASH_REMATCH[2]}"
    continue
  fi
  [[ "$line" =~ $raise_re ]] || fail "unexpected raise form in $current_fn: $line"
  code="${BASH_REMATCH[1]}" msg="${BASH_REMATCH[2]}" hint="${BASH_REMATCH[3]}"
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
if grep -Eq 'raise (check_violation|unique_violation|sqlstate)' <<<"$sql"; then
  fail 'new errors use registered TH codes (raise exception using errcode = ...)'
fi
for code in TH011 TH012 TH013 TH014 TH015; do
  [[ -n "$(registry_row "$code")" ]] || fail "registry is missing $code"
done

echo 'Enrolment and consent follow-up static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH972B_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  echo 'Enrolment and consent follow-up SQL test passed.'
fi
