#!/usr/bin/env bash
# Checks for the programmes, enrolments and consents migration.
#
#   bash supabase/tests/verify_enrolments_migration.sh            static checks
#   VERIFY_DB_URL=postgresql://... bash <this script>             static checks,
#       then the SQL RLS test against an already-migrated database (psql)
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

-- Synthetic identities only.
insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000913001', 'synthetic-user-01@example.test'),
  ('00000000-0000-4000-8000-000000913002', 'synthetic-user-02@example.test');

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
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''reminders'', ''v1'', ''Synthetic reminder wording'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%',
  'A: optional programme consent refused without core consent');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%',
  'A: consent-gated programme-data insert refused without core consent');

insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.a_hw')::uuid, 'core', 'v1', 'Synthetic core wording');
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

insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.a_hw')::uuid, 'reminders', 'v1', 'Synthetic reminder wording');
select th913_test.ok(
  public.has_consent(current_setting('th913.a_hw')::uuid, 'reminders'),
  'A: reminders consent live');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''share_care_team'', ''v1'', ''Synthetic sharing wording'')',
  current_setting('th913.a_hw')),
  '23514', '%', 'A: sharing consent without a named recipient refused');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, consent_text)
   values (%L, ''research'', ''synthetic-recipient'', ''v1'', ''Synthetic wording'')',
  current_setting('th913.a_hw')),
  '23514', '%', 'A: recipient on a non-sharing purpose refused');
insert into public.programme_consents
  (enrolment_id, purpose, recipient_ref, consent_version, consent_text)
values (current_setting('th913.a_hw')::uuid, 'share_care_team',
  'synthetic-connection-01', 'v1', 'Synthetic sharing wording');
select th913_test.ok(
  public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-01')
  and not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team',
    'synthetic-connection-02')
  and not public.has_consent(current_setting('th913.a_hw')::uuid, 'share_care_team'),
  'A: sharing consent is per recipient');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''core'', ''v2'', ''Synthetic core wording'')',
  current_setting('th913.a_hw')),
  '23505', '%', 'A: second live consent for the same purpose refused');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text, revoked_at)
   values (%L, ''research'', ''v1'', ''Synthetic wording'', now())',
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
  '23514', '%already revoked%', 'A: cannot un-revoke a consent');
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
insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.a_hw')::uuid, 'core', 'v2', 'Synthetic core wording v2');
select th913_test.ok(
  (select count(*) from public.programme_consents
   where enrolment_id = current_setting('th913.a_hw')::uuid and purpose = 'core') = 2,
  'A: re-grant adds a row and keeps the revoked one as history');

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
insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.a_bf')::uuid, 'core', 'v1', 'Synthetic core wording');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_bf')::uuid, 'share_care_team',
    'synthetic-connection-01'),
  'A: consent on one programme does not carry to another');

insert into public.account_consents (user_id, purpose, consent_version, consent_text)
values
  ('00000000-0000-4000-8000-000000913001', 'essential', 'v1', 'Synthetic essential wording'),
  ('00000000-0000-4000-8000-000000913001', 'diagnostics', 'v1', 'Synthetic diagnostics wording');
select th913_test.affects(
  'update public.account_consents set revoked_at = now() where purpose = ''diagnostics''',
  1, 'A: revokes an account-level consent');

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
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''core'', ''v9'', ''Synthetic wording'')',
  current_setting('th913.a_bf')),
  '42501', '%row-level security%', 'B: cannot add consent to A''s enrolment');
select th913_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
   values (''00000000-0000-4000-8000-000000913001'', ''essential'', ''v1'', ''Synthetic'')',
  '42501', '%row-level security%', 'B: cannot add account consent for A');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_hw')),
  '42501', '%row-level security%', 'B: cannot write data into A''s enrolment');

with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000913002', 'hw') returning id
) select set_config('th913.b_hw', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.b_hw')::uuid, 'core', 'v1', 'Synthetic core wording');
insert into th913_test.phi_probe (enrolment_id, note)
values (current_setting('th913.b_hw')::uuid, 'synthetic');
with i as (
  insert into public.enrolments (user_id, programme_code)
  values ('00000000-0000-4000-8000-000000913002', 'ca') returning id
) select set_config('th913.b_ca', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
values (current_setting('th913.b_ca')::uuid, 'core', 'v1', 'Synthetic core wording');

-- Leaving: keep for 30 days, then rejoin; or delete now.
select th913_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L',
  current_setting('th913.b_hw')), 1, 'B: leaves Heartwise keeping data');
select th913_test.ok(
  (select left_at is not null
      and purge_after = left_at + interval '30 days'
   from public.enrolments where id = current_setting('th913.b_hw')::uuid),
  'B: leaving sets left_at and purge_after = left_at + 30 days');
select th913_test.ok(
  not public.has_consent(current_setting('th913.b_hw')::uuid, 'core'),
  'B: consent is not honoured on a left enrolment');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.b_hw')),
  '42501', '%row-level security%', 'B: no new data on a left enrolment');
select th913_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, consent_text)
   values (%L, ''research'', ''v1'', ''Synthetic wording'')',
  current_setting('th913.b_hw')),
  '42501', '%row-level security%', 'B: no new consent on a left enrolment');
select th913_test.refused(format(
  'update public.enrolments set purge_after = now() + interval ''10 years'' where id = %L',
  current_setting('th913.b_hw')),
  '42501', 'permission denied%', 'B: cannot set purge_after directly');
select th913_test.affects(format(
  'update public.enrolments set status = ''focus'' where id = %L',
  current_setting('th913.b_hw')), 1, 'B: rejoins Heartwise');
select th913_test.ok(
  (select left_at is null and purge_after is null and status = 'focus'
   from public.enrolments where id = current_setting('th913.b_hw')::uuid)
  and public.has_consent(current_setting('th913.b_hw')::uuid, 'core')
  and (select count(*) from th913_test.phi_probe
       where enrolment_id = current_setting('th913.b_hw')::uuid) = 1,
  'B: rejoin reuses the row, clears purge, keeps data and consent');
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
                       where user_id = '00000000-0000-4000-8000-000000913001')
)::text, true);
select th913_test.ok(
  (current_setting('th913.a_counts')::jsonb ->> 'enrolments')::int = 2
  and (current_setting('th913.a_counts')::jsonb ->> 'programme_consents')::int = 5
  and (current_setting('th913.a_counts')::jsonb ->> 'account_consents')::int = 2,
  'A has 2 enrolments, 5 programme consents (2 revoked), 2 account consents before deletion');

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000913001', true);
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-000000913001","role":"authenticated"}', true);
set local role authenticated;

select th913_test.refused('select public.delete_my_app_data(''DELETE'')',
  '23514', '%not started%', 'A: deletion refused before the barrier is set');
select th913_test.ok(public.begin_account_deletion('DELETE'), 'A: deletion barrier set');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''st'')',
  '42501', '%row-level security%', 'A: no new enrolment once deletion has started');
select th913_test.refused(
  'insert into public.account_consents (user_id, purpose, consent_version, consent_text)
   values (''00000000-0000-4000-8000-000000913001'', ''cross_program_insights'', ''v1'', ''Synthetic'')',
  '42501', '%row-level security%', 'A: no new account consent once deletion has started');
select th913_test.ok(
  not public.has_consent(current_setting('th913.a_bf')::uuid, 'core'),
  'A: consent not honoured once deletion has started');
select th913_test.refused(format(
  'insert into th913_test.phi_probe (enrolment_id, note) values (%L, ''synthetic'')',
  current_setting('th913.a_bf')),
  '42501', '%row-level security%', 'A: no new programme data once deletion has started');

select set_config('th913.a_receipt', public.delete_my_app_data('DELETE')::text, true);
select th913_test.ok(
  current_setting('th913.a_receipt')::jsonb = current_setting('th913.a_counts')::jsonb,
  'A: delete_my_app_data returns counts only, matching the rows removed');
select th913_test.refused(
  'insert into public.enrolments (user_id, programme_code)
   values (''00000000-0000-4000-8000-000000913001'', ''st'')',
  '42501', '%row-level security%', 'A: no enrolment after the profile is deleted');
reset role;

select th913_test.ok(
  (select count(*) from public.enrolments
   where user_id = '00000000-0000-4000-8000-000000913001') = 0
  and (select count(*) from public.programme_consents
       where enrolment_id in (current_setting('th913.a_hw')::uuid,
                              current_setting('th913.a_bf')::uuid)) = 0
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
       where enrolment_id = current_setting('th913.b_hw')::uuid) = 1
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
if [[ -f "$programs_spec" ]]; then
  spec_codes=$(python3 -c 'import json,sys; print(" ".join(sorted(p["id"] for p in json.load(open(sys.argv[1])))) + " ")' "$programs_spec")
  [[ "$spec_codes" == "$expected" ]] || fail "spec programme ids '$spec_codes' differ from seed"
fi
grep -A1 "('ea', 'ease'" "$migration" | grep -q "array\[\]::text\[\]" || fail "Ease must receive no records"
grep -A1 "('sf', 'scrollfree'" "$migration" | grep -q "array\[\]::text\[\]" || fail "ScrollFree must receive no records"
require 'grant select on table public\.programmes to authenticated' 'catalogue readable by authenticated'

# Enrolments.
require 'user_id uuid not null references auth\.users\(id\) on delete cascade' 'enrolment owner FK cascades'
require 'programme_code text not null references public\.programmes\(code\)' 'enrolment programme FK'
require 'unique \(user_id, programme_code\)' 'one enrolment per user and programme'
require "status in \\('focus', 'learn_only', 'paused', 'left'\\)" 'enrolment status values'
require "new\\.purge_after = now\\(\\) \\+ interval '30 days'" 'database-managed 30-day purge date'
require 'grant update \(status, mode\) on table public\.enrolments' 'enrolment update limited to status and mode'
require 'account_deletion_started_at is null' 'deletion barrier on inserts'

# Consents.
require 'enrolment_id uuid not null references public\.enrolments\(id\) on delete cascade' 'programme consent hangs off enrolment'
require "unique nulls not distinct \\(enrolment_id, purpose, recipient_ref, revoked_at\\)" 'one live consent per enrolment, purpose and recipient'
require "'core', 'reminders', 'records_import', 'share_care_team'" 'programme consent purposes'
require "purpose in \\('share_care_team', 'share_caregiver'\\)\\) =" 'sharing needs a named recipient'
require "purpose in \\('essential', 'cross_program_insights', 'diagnostics'\\)" 'account consent purposes'
require 'consent_version text not null' 'consent version kept'
require 'consent_text text not null' 'consent wording kept'
require 'grant update \(revoked_at\) on table public\.programme_consents' 'programme consent update limited to revocation'
require 'grant update \(revoked_at\) on table public\.account_consents' 'account consent update limited to revocation'
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
  out=$(print_sql | psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1) || {
    echo "$out" >&2
    fail 'SQL RLS test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH913_SQL_TESTS_COMPLETE' || fail 'SQL RLS test did not complete'
  echo 'Enrolments SQL RLS test passed.'
fi
