#!/usr/bin/env bash
# Checks for the programmes, enrolments and consents migration.
#
#   bash supabase/tests/verify_enrolments_migration.sh            static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL RLS test against an already-migrated LOCAL
#       database (psql). Any host other than 127.0.0.1 or localhost is refused.
#   bash <this script> --print-sql                                print the SQL test
#
# The SQL test uses synthetic identities only, runs in one transaction and
# always rolls back.
set -euo pipefail

migration="supabase/migrations/202610170002_enrolments.sql"
programs_spec="tether_ui/spec/programs.json"

print_sql() {
  cat <<'SQL'
begin;

create schema th913_test;

create function th913_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

create function th913_test.refused(
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

-- Runs statements, then checks deferred constraints at once (the outer
-- transaction always rolls back, so commit-time checks would never fire).
create function th913_test.apply_now(p_sql text[])
returns void language plpgsql set search_path = '' as $f$
declare
  stmt text;
begin
  foreach stmt in array p_sql loop
    execute stmt;
  end loop;
  set constraints public.enrolments_focus_cap immediate;
  set constraints public.enrolments_focus_cap deferred;
end;
$f$;

-- Privileges held by anon, authenticated and PUBLIC, as one sorted string.
create function th913_test.table_acl(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s:%s:%s', c.relname, coalesce(r.rolname, 'PUBLIC'),
           a.privilege_type), ',' order by c.relname, coalesce(r.rolname, 'PUBLIC'),
           a.privilege_type), '')
  from pg_catalog.pg_class as c
  cross join lateral pg_catalog.aclexplode(c.relacl) as a
  left join pg_catalog.pg_roles as r on r.oid = a.grantee
  where c.oid = any (p_tables)
    and (a.grantee = 0 or r.rolname in ('anon', 'authenticated'));
$f$;

create function th913_test.column_acl(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s.%s:%s:%s', c.relname, at.attname,
           coalesce(r.rolname, 'PUBLIC'), a.privilege_type), ','
           order by c.relname, at.attname, coalesce(r.rolname, 'PUBLIC'), a.privilege_type), '')
  from pg_catalog.pg_attribute as at
  join pg_catalog.pg_class as c on c.oid = at.attrelid
  cross join lateral pg_catalog.aclexplode(at.attacl) as a
  left join pg_catalog.pg_roles as r on r.oid = a.grantee
  where c.oid = any (p_tables) and not at.attisdropped
    and (a.grantee = 0 or r.rolname in ('anon', 'authenticated'));
$f$;

create function th913_test.policy_list(p_tables regclass[])
returns text language sql stable set search_path = '' as $f$
  select coalesce(string_agg(format('%s:%s:%s:%s', c.relname, p.polname, p.polcmd,
           p.polpermissive), ',' order by c.relname, p.polname), '')
  from pg_catalog.pg_policy as p
  join pg_catalog.pg_class as c on c.oid = p.polrelid
  where c.oid = any (p_tables);
$f$;

create function th913_test.affects(p_sql text, p_rows integer, p_label text)
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

-- Stand-in for a programme-data table using the documented insert check:
-- owner via the enrolment, enrolment not left, core consent live.
create table th913_test.phi_probe (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments(id) on delete cascade,
  note text not null
);
alter table th913_test.phi_probe enable row level security;
alter table th913_test.phi_probe force row level security;
create policy phi_probe_select on th913_test.phi_probe for select to authenticated
using (exists (select 1 from public.enrolments e
  where e.id = enrolment_id and e.user_id = (select auth.uid())));
create policy phi_probe_insert on th913_test.phi_probe for insert to authenticated
with check (
  exists (select 1 from public.enrolments e
    where e.id = enrolment_id and e.user_id = (select auth.uid())
      and e.status <> 'left')
  and public.has_consent(enrolment_id, 'core')
);

grant usage on schema th913_test to anon, authenticated;
grant execute on all functions in schema th913_test to anon, authenticated;
grant select, insert on th913_test.phi_probe to authenticated;

-- Synthetic identities only.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-000000913001', 'synthetic-user-01@example.test',
   'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000913002', 'synthetic-user-02@example.test',
   'authenticated', 'authenticated');
select th913_test.ok(
  (select count(*) from public.profiles
   where id in ('00000000-0000-4000-8000-000000913001',
                '00000000-0000-4000-8000-000000913002')) = 2,
  'setup: the signup trigger created both synthetic profiles');

-- Synthetic consent documents: consent rows take their text from these.
insert into public.consent_documents (purpose, version, locale, body, effective_from) values
  ('core', 'v1', 'en', 'Synthetic core wording', now()),
  ('core', 'v2', 'en', 'Synthetic core wording v2', now()),
  ('core', 'v9', 'en', 'Synthetic wording', now()),
  ('reminders', 'v1', 'en', 'Synthetic reminder wording', now()),
  ('share_care_team', 'v1', 'en', 'Synthetic sharing wording', now()),
  ('research', 'v1', 'en', 'Synthetic research wording', now()),
  ('records_import', 'v1', 'en', 'Synthetic records wording', now()),
  ('essential', 'v1', 'en', 'Synthetic essential wording', now()),
  ('essential', 'v2', 'en', 'Synthetic', now()),
  ('diagnostics', 'v1', 'en', 'Synthetic diagnostics wording', now()),
  ('cross_program_insights', 'v1', 'en', 'Synthetic insights wording', now());

-- Privileges and policies -----------------------------------------------------
-- Pinned so that an accidental grant or policy change fails this test.
select th913_test.ok(
  th913_test.table_acl(array['public.profiles', 'public.quit_plans',
    'public.program_data']::regclass[]) =
  'profiles:authenticated:SELECT,'
  'program_data:authenticated:DELETE,program_data:authenticated:INSERT,'
  'program_data:authenticated:SELECT,program_data:authenticated:UPDATE,'
  'quit_plans:authenticated:SELECT',
  'existing tables: anon/authenticated/PUBLIC table privileges unchanged');
select th913_test.ok(
  th913_test.column_acl(array['public.profiles', 'public.quit_plans',
    'public.program_data']::regclass[]) =
  'profiles.avatar_path:authenticated:UPDATE,profiles.display_name:authenticated:UPDATE,'
  'profiles.locale:authenticated:UPDATE,profiles.onboarding_completed:authenticated:UPDATE,'
  'profiles.time_zone:authenticated:UPDATE,'
  'quit_plans.care_team_reminder:authenticated:INSERT,quit_plans.care_team_reminder:authenticated:UPDATE,'
  'quit_plans.custom_quit_reason:authenticated:INSERT,quit_plans.custom_quit_reason:authenticated:UPDATE,'
  'quit_plans.custom_smoking_trigger:authenticated:INSERT,quit_plans.custom_smoking_trigger:authenticated:UPDATE,'
  'quit_plans.daily_cigarette_use:authenticated:INSERT,quit_plans.daily_cigarette_use:authenticated:UPDATE,'
  'quit_plans.preparation_tasks:authenticated:INSERT,quit_plans.preparation_tasks:authenticated:UPDATE,'
  'quit_plans.quit_date:authenticated:INSERT,quit_plans.quit_date:authenticated:UPDATE,'
  'quit_plans.quit_day_check_in:authenticated:INSERT,quit_plans.quit_day_check_in:authenticated:UPDATE,'
  'quit_plans.quit_plan_path:authenticated:INSERT,quit_plans.quit_plan_path:authenticated:UPDATE,'
  'quit_plans.quit_reasons:authenticated:INSERT,quit_plans.quit_reasons:authenticated:UPDATE,'
  'quit_plans.readiness_path:authenticated:INSERT,quit_plans.readiness_path:authenticated:UPDATE,'
  'quit_plans.smoking_triggers:authenticated:INSERT,quit_plans.smoking_triggers:authenticated:UPDATE,'
  'quit_plans.support_people:authenticated:INSERT,quit_plans.support_people:authenticated:UPDATE,'
  'quit_plans.top_quit_reason:authenticated:INSERT,quit_plans.top_quit_reason:authenticated:UPDATE,'
  'quit_plans.treatment_support:authenticated:INSERT,quit_plans.treatment_support:authenticated:UPDATE,'
  'quit_plans.user_id:authenticated:INSERT,quit_plans.user_id:authenticated:UPDATE',
  'existing tables: anon/authenticated/PUBLIC column privileges unchanged');
select th913_test.ok(
  th913_test.policy_list(array['public.profiles', 'public.quit_plans',
    'public.program_data']::regclass[]) =
  'profiles:profiles_select_own:r:t,profiles:profiles_update_own:w:t,'
  'program_data:program_data_delete_own:d:t,program_data:program_data_insert_own:a:t,'
  'program_data:program_data_select_own:r:t,program_data:program_data_update_own:w:t,'
  'quit_plans:quit_plans_insert_own:a:t,quit_plans:quit_plans_select_own:r:t,'
  'quit_plans:quit_plans_update_own:w:t',
  'existing tables: policies unchanged');
select th913_test.ok(
  th913_test.table_acl(array['public.programmes', 'public.enrolments',
    'public.programme_consents', 'public.account_consents']::regclass[]) =
  'account_consents:authenticated:SELECT,'
  'enrolments:authenticated:DELETE,enrolments:authenticated:SELECT,'
  'programme_consents:authenticated:SELECT,'
  'programmes:authenticated:SELECT',
  'new tables: only the intended table privileges, none for anon');
select th913_test.ok(
  th913_test.column_acl(array['public.programmes', 'public.enrolments',
    'public.programme_consents', 'public.account_consents']::regclass[]) =
  'account_consents.consent_version:authenticated:INSERT,'
  'account_consents.locale:authenticated:INSERT,'
  'account_consents.purpose:authenticated:INSERT,'
  'account_consents.revoked_at:authenticated:UPDATE,'
  'account_consents.user_id:authenticated:INSERT,'
  'enrolments.mode:authenticated:INSERT,enrolments.mode:authenticated:UPDATE,'
  'enrolments.programme_code:authenticated:INSERT,'
  'enrolments.status:authenticated:INSERT,enrolments.status:authenticated:UPDATE,'
  'enrolments.user_id:authenticated:INSERT,'
  'programme_consents.consent_version:authenticated:INSERT,'
  'programme_consents.enrolment_id:authenticated:INSERT,'
  'programme_consents.locale:authenticated:INSERT,'
  'programme_consents.purpose:authenticated:INSERT,'
  'programme_consents.recipient_ref:authenticated:INSERT,'
  'programme_consents.revoked_at:authenticated:UPDATE,'
  'programme_consents.superseded_by:authenticated:UPDATE',
  'new tables: only the intended column privileges');
select th913_test.ok(
  (select bool_and(relrowsecurity and relforcerowsecurity) from pg_catalog.pg_class
   where oid in ('public.programmes'::regclass, 'public.enrolments'::regclass,
                 'public.programme_consents'::regclass, 'public.account_consents'::regclass,
                 'public.profiles'::regclass, 'public.quit_plans'::regclass,
                 'public.program_data'::regclass)),
  'RLS enabled and forced on new and existing tables');

-- Catalogue -----------------------------------------------------------------
select th913_test.ok(
  (select array_agg(code order by code) from public.programmes)
    = array['be','bf','ca','ck','ea','hw','nu','re','sd','sf','st'],
  'programmes seeded with exactly the 11 spec codes');
select th913_test.ok(
  (select bool_and(cardinality(receives_resources) = 0) from public.programmes
   where code in ('ea', 'sf')),
  'Ease and ScrollFree receive no record categories');

set local role anon;
select th913_test.refused('select count(*) from public.programmes',
  '42501', 'permission denied%', 'anon cannot read the catalogue');
select th913_test.refused('select count(*) from public.enrolments',
  '42501', 'permission denied%', 'anon cannot read enrolments');
select th913_test.refused(
  'select public.has_consent(gen_random_uuid(), ''core'')',
  '42501', 'permission denied%', 'anon cannot execute has_consent');
reset role;

-- User A ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000913001', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000913001","role":"authenticated"}', true);
set local role authenticated;

select th913_test.ok((select count(*) from public.programmes) = 11,
  'authenticated caller reads the catalogue');

with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000913001', 'hw') returning id
) select set_config('th913.a_hw', id::text, true) from i;

select th913_test.ok(
  not public.has_consent(current_setting('th913.a_hw')::uuid, 'core'),
  'A: no core consent yet');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''reminders'', ''v1'', ''en'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%',
  'A: optional programme consent refused without core consent');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%',
  'A: consent-gated programme-data insert refused without core consent');

insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.a_hw')::uuid, 'core', 'v1', 'en');
select th913_test.ok(
  public.has_consent(current_setting('th913.a_hw')::uuid, 'core'),
  'A: core consent live after grant');
select th913_test.ok(
  (select consent_version = 'v1' and consent_text = 'Synthetic core wording'
     and revoked_at is null and granted_at is not null
   from public.programme_consents
   where enrolment_id = current_setting('th913.a_hw')::uuid and purpose = 'core'),
  'A: consent row keeps version and wording');
select th913_test.affects(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')), 1,
  'A: consent-gated insert accepted once core consent is live');

insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.a_hw')::uuid, 'reminders', 'v1', 'en');
select th913_test.ok(
  public.has_consent(current_setting('th913.a_hw')::uuid, 'reminders'),
  'A: reminders consent live');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''share_care_team'', ''v1'', ''en'')',
  current_setting('th913.a_hw')),
  '23514', '%', 'A: sharing consent without a named recipient refused');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''research'', ''synthetic-recipient'', ''v1'', ''en'')',
  current_setting('th913.a_hw')),
  '23514', '%', 'A: recipient on a non-sharing purpose refused');
insert into public.programme_consents
  (enrolment_id, purpose, recipient_ref, consent_version, locale)
values (current_setting('th913.a_hw')::uuid, 'share_care_team',
  'synthetic-connection-01', 'v1', 'en');
select th913_test.ok(
  public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-01')
  and not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-02')
  and not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team'),
  'A: sharing consent is per recipient');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v2'', ''en'')',
  current_setting('th913.a_hw')),
  '23505', '%programme_consents_live_core_key%', 'A: second live consent for the same purpose refused');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale, revoked_at)
   values (%L, ''research'', ''v1'', ''en'', now())',
  current_setting('th913.a_hw')),
  '42501', 'permission denied%', 'A: cannot insert a pre-revoked consent');

-- Revocation is the only change allowed.
select th913_test.affects(format(
  'update public.programme_consents set revoked_at = now()
   where enrolment_id = %L and purpose = ''reminders''',
  current_setting('th913.a_hw')), 1, 'A: revokes reminders consent');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_hw')::uuid, 'reminders'),
  'A: revoked consent no longer counts');
select th913_test.refused(format(
  'update public.programme_consents set revoked_at = null
   where enrolment_id = %L and purpose = ''reminders''',
  current_setting('th913.a_hw')),
  'TH002', '%already revoked%', 'A: cannot un-revoke a consent');
select th913_test.refused(format(
  'update public.programme_consents set consent_text = ''changed''
   where enrolment_id = %L and purpose = ''core''',
  current_setting('th913.a_hw')),
  '42501', 'permission denied%', 'A: cannot rewrite consent wording');
select th913_test.refused(format(
  'delete from public.programme_consents where enrolment_id = %L',
  current_setting('th913.a_hw')),
  '42501', 'permission denied%', 'A: cannot delete consent history directly');

-- Revoking core switches off every other purpose of that enrolment.
update public.programme_consents set revoked_at = now()
where enrolment_id = current_setting('th913.a_hw')::uuid and purpose = 'core'
  and revoked_at is null;
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-01'),
  'A: sharing consent not honoured while core is revoked');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%',
  'A: consent-gated insert refused after core revocation');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.a_hw')::uuid, 'core', 'v2', 'en');
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.a_hw')::uuid and purpose = 'core') = 2,
  'A: re-grant adds a row and keeps the revoked one as history');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-01'),
  'A: sharing stays off after a core re-grant');
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.a_hw')::uuid
     and purpose = 'share_care_team' and revoked_at is not null) = 1
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th913.a_hw')::uuid
         and revoked_at is null) = 1,
  'A: core revocation revoked the sharing row, kept as history; only the new core is live');

-- Enrolment constraints.
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''hw'')',
  '23505', '%', 'A: one enrolment per programme');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code, mode)
   values (''00000000-0000-4000-8000-000000913001'', ''st'', ''quit'')',
  '23514', '%', 'A: quit/reduce mode only on BreatheFree and ScrollFree');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code, status)
   values (''00000000-0000-4000-8000-000000913001'', ''st'', ''left'')',
  '23514', '%', 'A: cannot insert an enrolment that is already left');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''zz'')',
  '23503', '%', 'A: unknown programme code refused');
with i as (
  insert into public.enrolments (user_id, programme_code, mode)
  values ('00000000-0000-4000-8000-000000913001', 'bf', 'reduce') returning id
) select set_config('th913.a_bf', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.a_bf')::uuid, 'core', 'v1', 'en');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_bf')::uuid, 'share_care_team',
    'synthetic-connection-01'),
  'A: consent on one programme does not carry to another');
do $loop$
begin
  for i in 1..5 loop
    insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
    values (current_setting('th913.a_bf')::uuid, 'reminders', 'v1', 'en');
    update public.programme_consents set revoked_at = now()
    where enrolment_id = current_setting('th913.a_bf')::uuid
      and purpose = 'reminders' and revoked_at is null;
  end loop;
end;
$loop$;
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.a_bf')::uuid
     and purpose = 'reminders' and revoked_at is not null) = 5
  and not public.has_consent(current_setting('th913.a_bf')::uuid, 'reminders'),
  'A: five grant/revoke cycles in one transaction never fail; all kept as history');

insert into public.account_consents (user_id, purpose, consent_version, locale)
values
  ('00000000-0000-4000-8000-000000913001', 'essential', 'v1', 'en'),
  ('00000000-0000-4000-8000-000000913001', 'diagnostics', 'v1', 'en');
select th913_test.affects(
  'update public.account_consents set revoked_at = now() where purpose = ''diagnostics''',
  1, 'A: revokes an account-level consent');
select th913_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, locale)
   values (''00000000-0000-4000-8000-000000913001'', ''essential'', ''v2'', ''en'')',
  '23505', '%account_consents_live_key%', 'A: second live account consent for a purpose refused');
do $loop$
begin
  for i in 1..5 loop
    insert into public.account_consents (user_id, purpose, consent_version, locale)
    values ('00000000-0000-4000-8000-000000913001', 'cross_program_insights', 'v1',
      'en');
    update public.account_consents set revoked_at = now()
    where purpose = 'cross_program_insights' and revoked_at is null;
  end loop;
end;
$loop$;
select th913_test.ok(
  (select count(*) from public.account_consents
   where purpose = 'cross_program_insights' and revoked_at is not null) = 5,
  'A: five account grant/revoke cycles in one transaction never fail; all kept');

-- Focus cap: at most two in focus, checked at commit.
select th913_test.ok(
  (select count(*) from public.enrolments where status = 'focus') = 2,
  'A: Heartwise and BreatheFree are in focus');
select th913_test.refused(
  'select th913_test.apply_now(array[''insert into public.enrolments (user_id, programme_code)
     values (''''00000000-0000-4000-8000-000000913001'''', ''''st'''')''])',
  'TH001', '%two programmes%', 'A: a third programme in focus is refused');
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-000000913001', 'st', 'learn_only') returning id
) select set_config('th913.a_st', id::text, true) from i;
select th913_test.refused(format(
  'select th913_test.apply_now(array[%L])',
  format('update public.enrolments set status = ''focus'' where id = %L',
    current_setting('th913.a_st'))),
  'TH001', '%two programmes%', 'A: promoting a third to focus without a swap is refused');
select th913_test.apply_now(array[
  format('update public.enrolments set status = ''focus'' where id = %L',
    current_setting('th913.a_st')),
  format('update public.enrolments set status = ''learn_only'' where id = %L',
    current_setting('th913.a_hw'))]);
select th913_test.ok(
  (select array_agg(programme_code order by programme_code) from public.enrolments
   where status = 'focus') = array['bf', 'st'],
  'A: swap (promote first, then demote) succeeds in one transaction');

-- User B ---------------------------------------------------------------------
reset role;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000913002', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000913002","role":"authenticated"}', true);
set local role authenticated;

select th913_test.ok((select count(*) from public.enrolments) = 0,
  'B: cannot read A''s enrolments');
select th913_test.ok((select count(*) from public.programme_consents) = 0,
  'B: cannot read A''s programme consents');
select th913_test.ok((select count(*) from public.account_consents) = 0,
  'B: cannot read A''s account consents');
select th913_test.ok((select count(*) from th913_test.phi_probe) = 0,
  'B: cannot read A''s programme data');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_hw')::uuid, 'core'),
  'B: has_consent is false for A''s enrolment');
select th913_test.affects(format(
  'update public.enrolments set status = ''paused'' where id = %L',
  current_setting('th913.a_hw')), 0, 'B: cannot update A''s enrolment');
select th913_test.affects(format(
  'delete from public.enrolments where id = %L',
  current_setting('th913.a_hw')), 0, 'B: cannot delete A''s enrolment');
select th913_test.affects(format(
  'update public.programme_consents set revoked_at = now() where enrolment_id = %L',
  current_setting('th913.a_hw')), 0, 'B: cannot revoke A''s consents');
select th913_test.affects(
  'update public.account_consents set revoked_at = now()
   where user_id = ''00000000-0000-4000-8000-000000913001''',
  0, 'B: cannot revoke A''s account consents');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''st'')',
  '42501', '%row-level security%', 'B: cannot enrol A');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''core'', ''v9'', ''en'')',
  current_setting('th913.a_bf')),
  '42501', '%row-level security%', 'B: cannot add consent to A''s enrolment');
select th913_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, locale)
   values (''00000000-0000-4000-8000-000000913001'', ''essential'', ''v1'', ''en'')',
  '42501', '%row-level security%', 'B: cannot add account consent for A');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%', 'B: cannot write data into A''s enrolment');

with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000913002', 'hw') returning id
) select set_config('th913.b_hw', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.b_hw')::uuid, 'core', 'v1', 'en');
insert into public.programme_consents
  (enrolment_id, purpose, recipient_ref, consent_version, locale)
values
  (current_setting('th913.b_hw')::uuid, 'share_care_team', 'synthetic-connection-02',
   'v1', 'en'),
  (current_setting('th913.b_hw')::uuid, 'research', null, 'v1', 'en'),
  (current_setting('th913.b_hw')::uuid, 'records_import', null, 'v1', 'en');
insert into th913_test.phi_probe (enrolment_id, note)
values (current_setting('th913.b_hw')::uuid, 'synthetic');
with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000913002', 'ca') returning id
) select set_config('th913.b_ca', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.b_ca')::uuid, 'core', 'v1', 'en');

-- Leaving: keep the data (no automatic purge), then rejoin; or delete now.
select th913_test.ok(
  public.has_consent(current_setting('th913.b_hw')::uuid, 'share_care_team',
    'synthetic-connection-02')
  and public.has_consent(current_setting('th913.b_hw')::uuid, 'research')
  and public.has_consent(current_setting('th913.b_hw')::uuid, 'records_import'),
  'B: sharing, research and records import are live before leaving');
select th913_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L',
  current_setting('th913.b_hw')), 1, 'B: leaves Heartwise keeping data');
select th913_test.ok(
  (select left_at is not null from public.enrolments
   where id = current_setting('th913.b_hw')::uuid)
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th913.b_hw')::uuid
         and purpose <> 'core' and revoked_at is null) = 0
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th913.b_hw')::uuid
         and purpose = 'core' and revoked_at is null) = 1,
  'B: leaving sets left_at and revokes every optional consent; core row stays');
select th913_test.ok(
  not public.has_consent(current_setting('th913.b_hw')::uuid, 'core'),
  'B: consent is not honoured on a left enrolment');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.b_hw')),
  '42501', '%row-level security%', 'B: no new data on a left enrolment');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''research'', ''v1'', ''en'')',
  current_setting('th913.b_hw')),
  '42501', '%row-level security%', 'B: no new consent on a left enrolment');
select th913_test.refused(format(
  'update public.enrolments set left_at = null where id = %L',
  current_setting('th913.b_hw')),
  '42501', 'permission denied%', 'B: cannot set left_at directly');
select th913_test.affects(format(
  'update public.enrolments set status = ''focus'' where id = %L',
  current_setting('th913.b_hw')), 1, 'B: rejoins Heartwise');
select th913_test.ok(
  (select left_at is null and status = 'focus'
   from public.enrolments where id = current_setting('th913.b_hw')::uuid)
  and public.has_consent(current_setting('th913.b_hw')::uuid, 'core')
  and (select count(*) from th913_test.phi_probe
       where enrolment_id = current_setting('th913.b_hw')::uuid) = 1,
  'B: rejoin reuses the row, clears left_at, keeps data and the core consent');
select th913_test.ok(
  not public.has_consent(current_setting('th913.b_hw')::uuid, 'share_care_team',
    'synthetic-connection-02')
  and not public.has_consent(current_setting('th913.b_hw')::uuid, 'research')
  and not public.has_consent(current_setting('th913.b_hw')::uuid, 'records_import'),
  'B: after rejoin, sharing, research and records import are off until granted again');
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.b_hw')::uuid
     and purpose in ('share_care_team', 'research', 'records_import')
     and revoked_at is not null) = 3,
  'B: the revoked optional consents are kept as history');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th913.b_hw')::uuid, 'research', 'v1', 'en');
select th913_test.ok(
  public.has_consent(current_setting('th913.b_hw')::uuid, 'research'),
  'B: an optional consent granted again after rejoin is live');
select th913_test.affects(format(
  'delete from public.enrolments where id = %L',
  current_setting('th913.b_ca')), 1, 'B: leaves ClearAir deleting data now');
reset role;
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.b_ca')::uuid) = 0,
  'delete-now removes that enrolment''s consents (cascade)');

-- Account deletion -----------------------------------------------------------
select set_config('th913.a_counts', jsonb_build_object(
  'profiles', 1, 'quit_plans', 0, 'program_data', 0,
  'enrolments', (select count(*) from public.enrolments
                 where user_id = '00000000-0000-4000-8000-000000913001'),
  'programme_consents', (select count(*) from public.programme_consents c
                         join public.enrolments e on e.id = c.enrolment_id
                         where e.user_id = '00000000-0000-4000-8000-000000913001'),
  'account_consents', (select count(*) from public.account_consents
                       where user_id = '00000000-0000-4000-8000-000000913001'),
  'sync_answers', 0, 'sync_lapses', 0, 'sync_areas', 0, 'sync_accounts', 0
)::text, true);
select th913_test.ok(
  (current_setting('th913.a_counts')::jsonb ->> 'enrolments')::int = 3
  and (current_setting('th913.a_counts')::jsonb ->> 'programme_consents')::int = 10
  and (current_setting('th913.a_counts')::jsonb ->> 'account_consents')::int = 7,
  'A has 3 enrolments, 10 programme consents (8 revoked), 7 account consents before deletion');

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000913001', true);
select set_config('request.jwt.claims', json_build_object(
  'sub', '00000000-0000-4000-8000-000000913001', 'role', 'authenticated',
  'amr', json_build_array(json_build_object(
    'method', 'password', 'timestamp', extract(epoch from now()) - 30)))::text, true);

-- delete_my_app_data runs in owner context, as delete_my_account runs it: the
-- superuser with A's claims. begin_account_deletion runs as authenticated.
select th913_test.refused('select public.delete_my_app_data(''DELETE'')',
  '23514', '%not started%', 'A owner: deletion refused before the barrier is set');
set local role authenticated;
select th913_test.ok(public.begin_account_deletion('DELETE'), 'A: deletion barrier set');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''nu'')',
  '42501', '%row-level security%', 'A: no new enrolment once deletion has started');
select th913_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, locale)
   values (''00000000-0000-4000-8000-000000913001'', ''cross_program_insights'', ''v1'', ''en'')',
  '42501', '%row-level security%', 'A: no new account consent once deletion has started');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_bf')::uuid, 'core'),
  'A: consent not honoured once deletion has started');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_bf')),
  '42501', '%row-level security%', 'A: no new programme data once deletion has started');

reset role;
select set_config('th913.a_receipt', public.delete_my_app_data('DELETE')::text, true);
set local role authenticated;
select th913_test.ok(
  current_setting('th913.a_receipt')::jsonb = current_setting('th913.a_counts')::jsonb,
  'A owner: delete_my_app_data returns counts only, matching the rows removed');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''nu'')',
  '42501', '%row-level security%', 'A: no enrolment after the profile is deleted');
reset role;

select th913_test.ok(
  (select count(*) from public.enrolments
   where user_id = '00000000-0000-4000-8000-000000913001') = 0
  and (select count(*) from public.programme_consents
       where enrolment_id in (current_setting('th913.a_hw')::uuid,
                              current_setting('th913.a_bf')::uuid,
                              current_setting('th913.a_st')::uuid)) = 0
  and (select count(*) from public.account_consents
       where user_id = '00000000-0000-4000-8000-000000913001') = 0
  and (select count(*) from th913_test.phi_probe
       where enrolment_id in (current_setting('th913.a_hw')::uuid,
                              current_setting('th913.a_bf')::uuid)) = 0
  and (select count(*) from public.profiles
       where id = '00000000-0000-4000-8000-000000913001') = 0,
  'deletion removed every A row, including enrolment-scoped data (cascade)');
select th913_test.ok(
  (select count(*) from public.enrolments
   where user_id = '00000000-0000-4000-8000-000000913002') = 1
  and (select count(*) from public.programme_consents
       where enrolment_id = current_setting('th913.b_hw')::uuid) = 5
  and (select count(*) from th913_test.phi_probe
       where enrolment_id = current_setting('th913.b_hw')::uuid) = 1,
  'deletion left B''s rows untouched');

select 'TH913_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

if [[ "${1:-}" == "--print-sql" ]]; then
  print_sql
  exit 0
fi

fail() {
  echo "Enrolments migration check failed: $1" >&2
  exit 1
}

# Accepts only postgres:// or postgresql:// URLs whose whole authority is
# [userinfo@]127.0.0.1|localhost[:port]: one '@' at most, no comma host lists,
# and no query string, fragment or whitespace anywhere (libpq parameters such
# as host= could redirect the connection).
url_shape='^postgres(ql)?://([^/]*)(/[^?#[:space:]]*)?$'
local_authority='^([^@/?#,[:space:]]*@)?(127\.0\.0\.1|localhost)(:[0-9]{1,5})?$'
db_url_is_local() {
  [[ "$1" =~ $url_shape ]] || return 1
  [[ "${BASH_REMATCH[2]}" =~ $local_authority ]]
}

# Self-test of the guard; runs with the static checks.
for u in 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' \
  'postgres://postgres@localhost:54322/postgres' 'postgresql://localhost/postgres'; do
  db_url_is_local "$u" || fail "local URL guard rejects a local URL ($u)"
done
for u in 'postgresql://postgres:postgres@db.example.test:5432/postgres' \
  'postgresql://postgres@127.0.0.1.example.test:5432/postgres' \
  'postgresql://postgres@localhost:54322/postgres?host=db.example.test' \
  'postgresql://postgres@localhost,db.example.test:5432/postgres' \
  'postgresql:///postgres' 'host=localhost dbname=postgres' \
  'postgresql://user@db.example.test/x@127.0.0.1' \
  'postgresql://u:p@ss@127.0.0.1/postgres' \
  'postgresql://u@db.example.test:5432@127.0.0.1/postgres' \
  'postgresql://u@db.example.test:5432@localhost:54322/postgres' \
  'postgresql://postgres@localhost:54322/postgres#db.example.test' \
  'postgresql://postgres@localhost#@db.example.test/postgres' \
  'postgresql://postgres@localhost:54322/post gres' \
  'postgresql://post gres@localhost:54322/postgres' \
  'postgresql://postgres@[::1]:54322/postgres' \
  'postgresql://postgres@localhost:543221/postgres'; do
  if db_url_is_local "$u"; then fail "local URL guard accepts a non-local URL ($u)"; fi
done

if [[ -n "${VERIFY_DB_URL:-}" ]] && ! db_url_is_local "$VERIFY_DB_URL"; then
  fail 'VERIFY_DB_URL must point at a local database (127.0.0.1 or localhost)'
fi

[[ -f "$migration" ]] || fail "missing $migration"

require() {
  grep -Eiq "$1" "$migration" || fail "$2"
}

count() {
  grep -Eic "$1" "$migration" || true
}

tables=(programmes enrolments programme_consents account_consents)
for t in "${tables[@]}"; do
  require "create table public\\.$t \\(" "table public.$t"
  require "alter table public\\.$t enable row level security" "RLS enabled on $t"
  require "alter table public\\.$t force row level security" "RLS forced on $t"
  require "revoke all on table public\\.$t from anon, authenticated" "default grants revoked on $t"
done

# Programmes: exactly the 11 spec codes, seeded once.
seeded=$(sed -n '/^insert into public\.programmes/,/;$/p' "$migration" |
  grep -Eo "^  \('[a-z]{2}'" | tr -d " ('" | sort | tr '\n' ' ')
expected="be bf ca ck ea hw nu re sd sf st "
[[ "$seeded" == "$expected" ]] || fail "programmes seed is '$seeded', expected '$expected'"
[[ -f "$programs_spec" ]] || fail "missing $programs_spec for the seed cross-check"
spec_rows=$(python3 -c 'import json,sys
for p in sorted(json.load(open(sys.argv[1])), key=lambda p: p["id"]):
    print("|".join([p["id"], p["name"], p["area"], p["archetype"]]))' "$programs_spec")
seed_rows=$(sed -n '/^insert into public\.programmes/,/;$/p' "$migration" |
  sed -nE "s/^  \('([a-z]{2})', '[a-z0-9_]+', '([^']+)', '([^']+)', '([^']+)',$/\1|\2|\3|\4/p" | sort)
[[ -n "$spec_rows" && "$spec_rows" == "$seed_rows" ]] ||
  fail "programmes seed (code, name, area, archetype) differs from $programs_spec"
grep -A1 "('ea', 'ease'" "$migration" | grep -q "array\[\]::text\[\]" || fail "Ease must receive no records"
grep -A1 "('sf', 'scrollfree'" "$migration" | grep -q "array\[\]::text\[\]" || fail "ScrollFree must receive no records"
require 'grant select on table public\.programmes to authenticated' 'catalogue readable by authenticated'

# Enrolments.
require 'user_id uuid not null references auth\.users\(id\) on delete cascade' 'enrolment owner FK cascades'
require 'programme_code text not null references public\.programmes\(code\)' 'enrolment programme FK'
require 'unique \(user_id, programme_code\)' 'one enrolment per user and programme'
require "status in \\('focus', 'learn_only', 'paused', 'left'\\)" 'enrolment status values'
if grep -Eiq 'purge_after|interval .30 days' "$migration"; then
  fail 'leaving must not schedule a purge (no automatic purge)'
fi
require 'new\.left_at = now\(\)' 'database-managed left_at'
require 'grant update \(status, mode\) on table public\.enrolments' 'enrolment update limited to status and mode'
require 'create constraint trigger enrolments_focus_cap' 'focus cap trigger'
require '^deferrable initially deferred$' 'focus cap checked at commit'
require "pg_advisory_xact_lock\\($" 'focus cap serialised per user'
require 'focus_count > 2' 'at most two in focus'

# Deletion barrier helper, used by every insert check in this migration.
barrier_body=$(sed -n '/create function public\.deletion_barrier_open()/,/^\$\$;/p' "$migration")
grep -Eq '^security invoker$' <<<"$barrier_body" || fail 'deletion_barrier_open must be security invoker'
grep -Eq '^volatile$' <<<"$barrier_body" || fail 'deletion_barrier_open must be volatile'
grep -Eq '^  for share;$' <<<"$barrier_body" || fail 'deletion_barrier_open must lock the profile row for share'
grep -Eq 'account_deletion_started_at is null' <<<"$barrier_body" || fail 'deletion_barrier_open checks the barrier'
insert_policies=$(count '^on public\.(enrolments|programme_consents|account_consents) for insert$')
barrier_uses=$(grep -Ev '^(create|revoke|grant|comment) |^ *--' "$migration" |
  grep -Eo 'public\.deletion_barrier_open\(\)' | wc -l | tr -d ' ')
[[ "$insert_policies" -eq 3 && "$barrier_uses" -eq 3 ]] ||
  fail "every insert policy must use deletion_barrier_open ($insert_policies policies, $barrier_uses uses)"
require 'grant execute on function public\.deletion_barrier_open\(\) to authenticated' 'barrier helper granted'

# Consents.
require 'enrolment_id uuid not null references public\.enrolments\(id\) on delete cascade' 'programme consent hangs off enrolment'
require "on public\\.programme_consents \\(enrolment_id, purpose, coalesce\\(recipient_ref, ''\\)\\)" 'one live consent per enrolment, purpose and recipient'
require "on public\\.account_consents \\(user_id, purpose\\)" 'one live account consent per purpose'
[[ "$(count '^where revoked_at is null;$')" -eq 2 ]] || fail 'live-row unique indexes must be partial on revoked_at is null'
if grep -Eiq 'nulls not distinct' "$migration"; then
  fail 'uniqueness must not include revocation history (use partial indexes on live rows)'
fi
require "'core', 'reminders', 'records_import', 'share_care_team'" 'programme consent purposes'
require "purpose in \\('share_care_team', 'share_caregiver'\\)\\) =" 'sharing needs a named recipient'
require "purpose in \\('essential', 'cross_program_insights', 'diagnostics'\\)" 'account consent purposes'
require 'consent_version text not null' 'consent version kept'
require 'consent_text text not null' 'consent wording kept'
require 'grant update \(revoked_at\) on table public\.programme_consents' 'programme consent update limited to revocation'
require 'grant update \(revoked_at\) on table public\.account_consents' 'account consent update limited to revocation'
require 'create trigger programme_consents_revoke_with_core' 'core revocation revokes the enrolment consents'
require "old\\.purpose = 'core' and old\\.revoked_at is null and new\\.revoked_at is not null" 'core revocation trigger condition'
require 'create trigger enrolments_revoke_on_leave' 'leaving revokes optional consents'
require "when \\(new\\.status = 'left' and old\\.status is distinct from 'left'\\)" 'leave trigger condition'
require "purpose <> 'core'" 'leaving keeps only core'
require 'create function public\.has_consent\(' 'has_consent defined'
require "public\\.has_consent\\(programme_consents\\.enrolment_id, 'core'\\)" 'optional consent gated on core'
has_consent_body=$(sed -n '/create function public\.has_consent(/,/^\$\$;/p' "$migration")
grep -Eq '^stable$' <<<"$has_consent_body" || fail 'has_consent must be stable'
grep -Eq '^security invoker$' <<<"$has_consent_body" || fail 'has_consent must be security invoker'
grep -Eq 'auth\.uid\(\)' <<<"$has_consent_body" || fail 'has_consent must scope to the caller'
require 'revoke all on function public\.has_consent\(uuid, text, text\)' 'has_consent default execute revoked'
require 'grant execute on function public\.has_consent\(uuid, text, text\) to authenticated' 'has_consent granted to authenticated'

# Functions: search_path pinned; the only security definer is delete_my_app_data.
functions=$(count '^create (or replace )?function ')
pinned=$(count "^set search_path = ''$")
[[ "$functions" -eq "$pinned" ]] || fail "$functions functions but $pinned with search_path = ''"
[[ "$(count '^security definer$')" -eq 1 ]] || fail 'only delete_my_app_data may be security definer'

# Deletion.
require 'create or replace function public\.delete_my_app_data\(p_confirmation text\)' 'deletion function extended'
require "p_confirmation is distinct from 'DELETE'" 'explicit confirmation kept'
require "Account deletion was not started" 'deletion barrier kept'
for t in programme_consents enrolments account_consents program_data quit_plans; do
  require "delete from public\\.$t" "deletion covers $t"
done
require 'delete from public\.profiles where id = caller_id' 'deletion covers profiles'
require "'enrolments', deleted_enrolments" 'enrolment count returned'
require 'revoke all on function public\.delete_my_app_data\(text\)' 'deletion default execute revoked'

# Never loosen.
if grep -Eiq 'disable row level security|no force row level security|bypassrls|security_barrier *= *false' "$migration"; then
  fail 'migration must not disable or bypass RLS'
fi
if grep -Eiq 'grant .* to (.*[^a-z_])?anon([^a-z_]|$)' "$migration"; then
  fail 'nothing is granted to anon'
fi
if grep -Eiq 'grant all' "$migration"; then
  fail 'no blanket grants'
fi
if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  fail 'migration must not contain credentials or service-role use'
fi

echo 'Enrolments migration static policy checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  # Connection environment variables could override the checked URL.
  out=$(print_sql | env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
    psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL RLS test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH913_SQL_TESTS_COMPLETE' || fail 'SQL RLS test did not complete'
  echo 'Enrolments SQL RLS test passed.'
fi
