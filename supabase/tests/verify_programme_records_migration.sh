#!/usr/bin/env bash
# Checks the programme records: seven tables with forced row-level security,
# composite enrolment keys, payload and attribute checks, append-only rows,
# truncate guards, and delete_my_app_data and delete_enrolment_now counting
# the new tables.
#
#   bash supabase/tests/verify_programme_records_migration.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator, so the URL's user must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: as
#       authenticated, a synthetic member with a live core consent stores a
#       Heartwise observation whose attributes hold a key no metric allows,
#       and it reports:
#         TH914B_CONTROL_UNKNOWN_KEY_REFUSED  (expected with the migration:
#             23514)
#         TH914B_CONTROL_TABLE_ABSENT         (a tree without the migration:
#             42P01, the table does not exist)
#         TH914B_CONTROL_UNEXPECTED           (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180013_programme_records.sql"
app_data_source="supabase/migrations/202610180011_care.sql"
delete_now_source="supabase/migrations/202610180012_enrolment_delete_now.sql"
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
  if pg_catalog.to_regclass('public.observations') is null
     or pg_catalog.to_regprocedure('public.delete_enrolment_now(uuid,text)') is null
     or pg_catalog.to_regprocedure('public.delete_my_account(text)') is null then
    raise exception 'FAIL setup: the programme record tables, public.delete_enrolment_now(uuid,text) and public.delete_my_account(text) are needed';
  end if;
end;
$setup$;

-- Constraint definitions print timestamps in the session time zone.
set local timezone = 'UTC';
select set_config('th914b.superuser', session_user, true);

create schema th914b_test;

create function th914b_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with one of the SQLSTATEs in p_states ("a|b") and a
-- message like p_message_like; when p_hint is given, the hint must equal it.
create function th914b_test.refused(
  p_sql text, p_states text, p_message_like text, p_label text, p_hint text default null)
returns void language plpgsql set search_path = '' as $f$
declare
  got_hint text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics got_hint = pg_exception_hint;
    if sqlstate = any (pg_catalog.string_to_array(p_states, '|')) and sqlerrm like p_message_like
       and (p_hint is null or got_hint is not distinct from p_hint) then
      raise notice 'PASS % (% %)', p_label, sqlstate, sqlerrm;
      return;
    end if;
    raise exception 'FAIL % (got % % hint %)', p_label, sqlstate, sqlerrm, got_hint;
  end;
  raise exception 'FAIL % (statement succeeded)', p_label;
end;
$f$;

create function th914b_test.affects(p_sql text, p_rows integer, p_label text)
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

-- A value stored with set_config('th914b.<name>', ...).
create function th914b_test.v(p_name text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.current_setting('th914b.' || p_name)
$f$;

-- Token claims for p_sub with one password sign-in 30 seconds ago.
create function th914b_test.claims(p_sub text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object('role', 'authenticated', 'aud', 'authenticated', 'sub', p_sub,
    'amr', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - 30)))::text
$f$;

-- Switches the session to p_login acting as p_role with p_claims, the way
-- PostgREST (authenticator) and the sync service (thsync) do; or back to the
-- superuser that started the test. No SET clause on purpose: SET LOCAL
-- inside a function with one would be undone when it returns.
create function th914b_test.act_as(p_login text, p_claims text, p_role text default 'authenticated')
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th914b.superuser') then
    execute pg_catalog.format('set local role %I', p_role);
  end if;
end;
$f$;

-- An observation insert for the enrolment stored as th914b.<p_key> (its
-- programme is the key's suffix unless p_code is given). The member is
-- auth.uid() unless p_user is given.
create function th914b_test.obs_sql(
  p_key text, p_metric text, p_unit text, p_value text, p_attributes text default '{}',
  p_code text default null, p_user text default null, p_submission text default null,
  p_effective text default null)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.format(
    'insert into public.observations (user_id, enrolment_id, programme_code, submission_id, metric, value,'
    ' unit_ucum, effective_at, attributes) values (%s, %L, %L, %s, %L, %s, %L, %s, %L)',
    coalesce(pg_catalog.quote_literal(p_user) || '::uuid', 'auth.uid()'), th914b_test.v(p_key),
    coalesce(p_code, pg_catalog.split_part(p_key, '_', 2)),
    coalesce(pg_catalog.quote_literal(p_submission) || '::uuid', 'gen_random_uuid()'),
    p_metric, p_value, p_unit, coalesce(p_effective, 'now()'), p_attributes)
$f$;

-- A programme entry insert, built like obs_sql.
create function th914b_test.entry_sql(
  p_key text, p_kind text, p_payload text, p_code text default null, p_user text default null,
  p_submission text default null, p_occurred text default null)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.format(
    'insert into public.programme_entries (user_id, enrolment_id, programme_code, submission_id, kind,'
    ' occurred_at, payload) values (%s, %L, %L, %s, %L, %s, %L)',
    coalesce(pg_catalog.quote_literal(p_user) || '::uuid', 'auth.uid()'), th914b_test.v(p_key),
    coalesce(p_code, pg_catalog.split_part(p_key, '_', 2)),
    coalesce(pg_catalog.quote_literal(p_submission) || '::uuid', 'gen_random_uuid()'),
    p_kind, coalesce(p_occurred, 'now()'), p_payload)
$f$;

-- The rows a user holds in every member table, keyed like the
-- delete_my_app_data receipt.
create function th914b_test.counts(p_user uuid)
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

-- Member rows plus the identity.
create function th914b_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select th914b_test.counts(p_user) || pg_catalog.jsonb_build_object(
    'users', (select count(*) from auth.users where id = p_user))
$f$;

-- The rows delete_enrolment_now deletes for enrolment p_enrolment of p_user
-- in programme p_programme, keyed like its receipt.
create function th914b_test.rows_for(p_user uuid, p_enrolment uuid, p_programme text)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'quit_plans', case when p_programme = 'bf'
                       then (select count(*) from public.quit_plans where user_id = p_user) else 0 end,
    'program_data', (select count(*) from public.program_data
                     where user_id = p_user
                       and program_id = (select slug from public.programmes where code = p_programme)),
    'enrolments', (select count(*) from public.enrolments where id = p_enrolment),
    'programme_consents', (select count(*) from public.programme_consents where enrolment_id = p_enrolment),
    'sync_answers', (select count(*) from public.sync_answer
                     where user_id = p_user and programme_code = p_programme),
    'sync_lapses', (select count(*) from public.sync_lapse
                    where user_id = p_user and programme_code = p_programme),
    'sync_areas', (select count(*) from public.sync_area where enrolment_id = p_enrolment),
    'care_share_access', (select count(*) from public.care_share_access
                          where share_id in (select id from public.care_shares where enrolment_id = p_enrolment)),
    'care_messages', (select count(*) from public.care_messages
                      where enrolment_id = p_enrolment
                         or share_id in (select id from public.care_shares where enrolment_id = p_enrolment)),
    'care_shares', (select count(*) from public.care_shares where enrolment_id = p_enrolment),
    'caregiver_events', (select count(*) from public.caregiver_events
                         where caregiver_id in (select id from public.caregivers where enrolment_id = p_enrolment)),
    'caregivers', (select count(*) from public.caregivers where enrolment_id = p_enrolment),
    'observations', (select count(*) from public.observations where enrolment_id = p_enrolment),
    'programme_entries', (select count(*) from public.programme_entries where enrolment_id = p_enrolment),
    'rescue_events', (select count(*) from public.rescue_events where enrolment_id = p_enrolment),
    'lesson_progress', (select count(*) from public.lesson_progress where enrolment_id = p_enrolment),
    'programme_reminders', (select count(*) from public.programme_reminders where enrolment_id = p_enrolment))
$f$;

-- A synthetic member p_user (key p_key) enrolled, each with a core consent,
-- in every programme in p_codes (hw in focus, the others learn_only), plus nu
-- with no consent at all when p_full. With p_full also a quit plan, Heartwise
-- and Steady program data, an account consent, a sync account, sync rows for
-- hw and st, a supporter listing bf, a Stride caregiver with its consent and
-- an event, and a clinic connection with a Checkup sharing consent, a share,
-- an access row and a message. Enrolment ids are stored as th914b.<key>_<code>.
create function th914b_test.seed(p_user uuid, p_key text, p_codes text[], p_full boolean, p_org uuid)
returns void language plpgsql set search_path = '' as $f$
declare
  code text;
  enrolment uuid;
  connection uuid;
  caregiver uuid;
  share_consent uuid;
  share uuid;
begin
  insert into auth.users (id, email, aud, role) values
    (p_user, 'synthetic-' || p_key || '-914b@example.test', 'authenticated', 'authenticated');
  foreach code in array p_codes loop
    insert into public.enrolments (user_id, programme_code, status)
    values (p_user, code, case when code = 'hw' then 'focus' else 'learn_only' end)
    returning id into enrolment;
    perform pg_catalog.set_config('th914b.' || p_key || '_' || code, enrolment::text, true);
    insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
    values (enrolment, 'core', 'v1-draft', 'en');
  end loop;
  if not p_full then
    return;
  end if;
  insert into public.enrolments (user_id, programme_code, status)
  values (p_user, 'nu', 'learn_only') returning id into enrolment;
  perform pg_catalog.set_config('th914b.' || p_key || '_nu', enrolment::text, true);
  insert into public.quit_plans (user_id, quit_date) values (p_user, current_date);
  insert into public.program_data (user_id, program_id, payload) values
    (p_user, 'heartwise', '{}'), (p_user, 'steady', '{}');
  insert into public.account_consents (user_id, purpose, consent_version, locale)
  values (p_user, 'essential', 'v1-draft', 'en');
  insert into public.sync_account (user_id) values (p_user);
  foreach code in array array['hw', 'st'] loop
    insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
    values (p_user, th914b_test.v(p_key || '_' || code)::uuid, code, 1, 1);
    insert into public.sync_answer (user_id, programme_code, screen_id, payload)
    values (p_user, code, code || '_q1', '{"answer": 1}');
    insert into public.sync_lapse (user_id, programme_code, ordinal, at)
    values (p_user, code, 0, pg_catalog.now());
  end loop;
  insert into public.supporters (user_id, name, phone, programme_codes)
  values (p_user, 'Synthetic Supporter', '+15550109141', '{bf}');
  insert into public.caregivers (user_id, enrolment_id, name, phone)
  values (p_user, th914b_test.v(p_key || '_sd')::uuid, 'Synthetic Caregiver', '+15550109142')
  returning id into caregiver;
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (th914b_test.v(p_key || '_sd')::uuid, 'share_caregiver', caregiver::text, 'v1-draft', 'en');
  insert into public.caregiver_events (user_id, caregiver_id, kind, occurred_at)
  values (p_user, caregiver, 'sd.session_finished', pg_catalog.now());
  insert into public.care_connections (user_id, org_id) values (p_user, p_org) returning id into connection;
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (th914b_test.v(p_key || '_ck')::uuid, 'share_care_team', connection::text, 'v1-draft', 'en')
  returning id into share_consent;
  insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
  values (p_user, th914b_test.v(p_key || '_ck')::uuid, connection, share_consent, 'message_attachment',
          '{"summary": "synthetic"}')
  returning id into share;
  insert into public.care_share_access (user_id, share_id, channel) values (p_user, share, 'secure_link');
  insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
  values (p_user, connection, th914b_test.v(p_key || '_ck')::uuid, 'Synthetic topic',
          'Synthetic attached message', share);
end;
$f$;

grant usage on schema th914b_test to public;
grant execute on all functions in schema th914b_test to public;
revoke all on function th914b_test.seed(uuid, text, text[], boolean, uuid) from public;

-- Catalogue -----------------------------------------------------------------------------
-- The reviewed constraints of the seven tables, as pg_get_constraintdef prints
-- them (schema prefixes removed), ordered by constraint name.
select set_config('th914b.constraints', btrim($checks$
lesson_progress.lesson_progress_enrolment_fkey: FOREIGN KEY (enrolment_id, user_id, programme_code) REFERENCES enrolments(id, user_id, programme_code) ON DELETE CASCADE
lesson_progress.lesson_progress_lesson_id_check: CHECK ((lesson_id ~ '^[a-z0-9][a-z0-9_.-]{0,79}$'::text))
lesson_progress.lesson_progress_pkey: PRIMARY KEY (enrolment_id, lesson_id)
lesson_progress.lesson_progress_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
notification_preferences.notification_preferences_pkey: PRIMARY KEY (user_id)
notification_preferences.notification_preferences_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
observations.observations_attributes_check: CHECK (((jsonb_typeof(attributes) = 'object'::text) AND (octet_length((attributes)::text) <= 2048)))
observations.observations_effective_at_check: CHECK (((effective_at >= '1900-01-01 00:00:00+00'::timestamp with time zone) AND (effective_at <= (created_at + '1 day'::interval))))
observations.observations_enrolment_fkey: FOREIGN KEY (enrolment_id, user_id, programme_code) REFERENCES enrolments(id, user_id, programme_code) ON DELETE CASCADE
observations.observations_metric_check: CHECK ((((metric = ANY (ARRAY['bp_systolic'::text, 'bp_diastolic'::text])) AND (unit_ucum = 'mm[Hg]'::text) AND (programme_code = 'hw'::text)) OR ((metric = 'heart_rate'::text) AND (unit_ucum = '/min'::text) AND (programme_code = 'hw'::text)) OR ((metric = ANY (ARRAY['chol_total'::text, 'chol_ldl'::text, 'chol_hdl'::text, 'triglycerides'::text])) AND (unit_ucum = 'mg/dL'::text) AND (programme_code = 'hw'::text)) OR ((metric = 'glucose'::text) AND (unit_ucum = 'mg/dL'::text) AND (programme_code = 'st'::text)) OR ((metric = 'a1c'::text) AND (unit_ucum = '%'::text) AND (programme_code = 'st'::text)) OR ((metric = 'egfr'::text) AND (unit_ucum = 'mL/min/{1.73_m2}'::text) AND (programme_code = 're'::text)) OR ((metric = 'urine_acr'::text) AND (unit_ucum = 'mg/g'::text) AND (programme_code = 're'::text)) OR ((metric = 'alt'::text) AND (unit_ucum = 'U/L'::text) AND (programme_code = 're'::text)) OR ((metric = 'peak_flow'::text) AND (unit_ucum = 'L/min'::text) AND (programme_code = 'ca'::text))))
observations.observations_pkey: PRIMARY KEY (id)
observations.observations_submission_key: UNIQUE (enrolment_id, submission_id, metric)
observations.observations_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
observations.observations_value_check: CHECK (((value >= (0)::numeric) AND (value <= (10000)::numeric)))
programme_entries.programme_entries_enrolment_fkey: FOREIGN KEY (enrolment_id, user_id, programme_code) REFERENCES enrolments(id, user_id, programme_code) ON DELETE CASCADE
programme_entries.programme_entries_kind_check: CHECK ((kind = ANY (ARRAY['checkin'::text, 'ca.zone_check'::text, 'ca.symptom'::text, 'ea.mood'::text, 'ea.check_back'::text, 'sd.session'::text, 'sd.fall'::text, 'sf.pause'::text, 'ck.done'::text, 'be.diary'::text, 'be.survivorship'::text])))
programme_entries.programme_entries_kind_programme_check: CHECK (((kind = 'checkin'::text) OR (split_part(kind, '.'::text, 1) = programme_code)))
programme_entries.programme_entries_occurred_at_check: CHECK (((occurred_at >= '2000-01-01 00:00:00+00'::timestamp with time zone) AND (occurred_at <= (created_at + '00:05:00'::interval))))
programme_entries.programme_entries_payload_check: CHECK (((jsonb_typeof(payload) = 'object'::text) AND (octet_length((payload)::text) <= 4096)))
programme_entries.programme_entries_pkey: PRIMARY KEY (id)
programme_entries.programme_entries_submission_key: UNIQUE (enrolment_id, submission_id)
programme_entries.programme_entries_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
programme_reminders.programme_reminders_enrolment_fkey: FOREIGN KEY (enrolment_id, user_id, programme_code) REFERENCES enrolments(id, user_id, programme_code) ON DELETE CASCADE
programme_reminders.programme_reminders_pkey: PRIMARY KEY (enrolment_id)
programme_reminders.programme_reminders_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
rescue_events.rescue_events_enrolment_check: CHECK (((enrolment_id IS NULL) = (programme_code IS NULL)))
rescue_events.rescue_events_enrolment_fkey: FOREIGN KEY (enrolment_id, user_id, programme_code) REFERENCES enrolments(id, user_id, programme_code) ON DELETE CASCADE
rescue_events.rescue_events_helped_check: CHECK ((helped = ANY (ARRAY['yes'::text, 'a_little'::text, 'no'::text])))
rescue_events.rescue_events_intensity_after_check: CHECK (((intensity_after >= 0) AND (intensity_after <= 10)))
rescue_events.rescue_events_intensity_before_check: CHECK (((intensity_before >= 0) AND (intensity_before <= 10)))
rescue_events.rescue_events_opened_at_check: CHECK (((opened_at >= '2000-01-01 00:00:00+00'::timestamp with time zone) AND (opened_at <= (created_at + '00:05:00'::interval))))
rescue_events.rescue_events_pkey: PRIMARY KEY (id)
rescue_events.rescue_events_programme_check: CHECK (((programme_code IS NULL) OR (programme_code = 'bf'::text)))
rescue_events.rescue_events_submission_key: UNIQUE (user_id, submission_id)
rescue_events.rescue_events_tool_check: CHECK ((tool ~ '^[a-z0-9_]{1,40}$'::text))
rescue_events.rescue_events_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
wellbeing_baseline.wellbeing_baseline_age_range_check: CHECK ((age_range ~ '^[0-9]{2}_([0-9]{2}|plus)$'::text))
wellbeing_baseline.wellbeing_baseline_pkey: PRIMARY KEY (user_id)
wellbeing_baseline.wellbeing_baseline_sleep_band_check: CHECK ((sleep_band = ANY (ARRAY['lt5'::text, '5_6'::text, '7_8'::text, '9plus'::text])))
wellbeing_baseline.wellbeing_baseline_stress_band_check: CHECK ((stress_band = ANY (ARRAY['low'::text, 'some'::text, 'high'::text])))
wellbeing_baseline.wellbeing_baseline_user_id_fkey: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
$checks$, E'\n'), true);
select th914b_test.ok(
  (select string_agg(relname || ':' || relrowsecurity || ':' || relforcerowsecurity, ',' order by relname)
   from pg_catalog.pg_class
   where relnamespace = 'public'::regnamespace and relkind = 'r'
     and relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                     'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'lesson_progress:true:true,notification_preferences:true:true,observations:true:true,'
  'programme_entries:true:true,programme_reminders:true:true,rescue_events:true:true,'
  'wellbeing_baseline:true:true',
  'catalogue: the seven tables exist with row-level security enabled and forced');
select th914b_test.ok(
  (select string_agg(t.relname || '(' || t.cols || ')', ' ' order by t.relname)
   from (select c.relname,
                string_agg(a.attname || ' ' || format_type(a.atttypid, a.atttypmod)
                           || case when a.attnotnull then ' not null' else '' end, ',' order by a.attnum) as cols
         from pg_catalog.pg_class as c
         join pg_catalog.pg_attribute as a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
         where c.relnamespace = 'public'::regnamespace
           and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                             'programme_reminders', 'notification_preferences', 'wellbeing_baseline')
         group by c.relname) as t) =
  'lesson_progress(user_id uuid not null,enrolment_id uuid not null,programme_code text not null,'
  'lesson_id text not null,completed_at timestamp with time zone not null) '
  'notification_preferences(user_id uuid not null,reminders_enabled boolean not null,'
  'sensitive_details boolean not null,quiet_hours_enabled boolean not null,'
  'created_at timestamp with time zone not null,updated_at timestamp with time zone not null) '
  'observations(id uuid not null,user_id uuid not null,enrolment_id uuid not null,programme_code text not null,'
  'submission_id uuid not null,metric text not null,value numeric(9,3) not null,unit_ucum text not null,'
  'effective_at timestamp with time zone not null,attributes jsonb not null,'
  'created_at timestamp with time zone not null) '
  'programme_entries(id uuid not null,user_id uuid not null,enrolment_id uuid not null,'
  'programme_code text not null,submission_id uuid not null,kind text not null,'
  'occurred_at timestamp with time zone not null,payload jsonb not null,'
  'created_at timestamp with time zone not null) '
  'programme_reminders(user_id uuid not null,enrolment_id uuid not null,programme_code text not null,'
  'remind_at time without time zone not null,created_at timestamp with time zone not null,'
  'updated_at timestamp with time zone not null) '
  'rescue_events(id uuid not null,user_id uuid not null,enrolment_id uuid,programme_code text,'
  'submission_id uuid not null,tool text not null,opened_at timestamp with time zone not null,'
  'intensity_before smallint,intensity_after smallint,helped text,escalated boolean not null,'
  'created_at timestamp with time zone not null) '
  'wellbeing_baseline(user_id uuid not null,age_range text,sleep_band text,stress_band text,'
  'created_at timestamp with time zone not null,updated_at timestamp with time zone not null)',
  'catalogue: exactly the reviewed columns, types and nullability; no source or record_item_id column');
select th914b_test.ok(
  (select count(*) = 3
     and bool_and(pg_catalog.pg_get_expr(d.adbin, d.adrelid) = 'gen_random_uuid()')
   from pg_catalog.pg_class as c
   join pg_catalog.pg_attribute as a on a.attrelid = c.oid and a.attname = 'id'
   join pg_catalog.pg_attrdef as d on d.adrelid = c.oid and d.adnum = a.attnum
   where c.relnamespace = 'public'::regnamespace
     and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline'))
  and not exists (
    select 1 from pg_catalog.pg_attribute as a
    join pg_catalog.pg_class as c on c.oid = a.attrelid
    left join pg_catalog.pg_attrdef as d on d.adrelid = a.attrelid and d.adnum = a.attnum
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                        'programme_reminders', 'notification_preferences', 'wellbeing_baseline')
      and (a.attidentity <> '' or coalesce(pg_catalog.pg_get_expr(d.adbin, d.adrelid), '') like '%nextval%')),
  'catalogue: the three ids default to gen_random_uuid(); no identity column or sequence');
select th914b_test.ok(
  (select string_agg(c.relname || '.' || k.conname || ': '
                     || replace(pg_catalog.pg_get_constraintdef(k.oid), 'public.', ''), E'\n'
                     order by k.conname)
   from pg_catalog.pg_constraint as k
   join pg_catalog.pg_class as c on c.oid = k.conrelid
   where c.relnamespace = 'public'::regnamespace
     and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  current_setting('th914b.constraints'),
  'catalogue: every check, unique, primary and foreign key on the seven tables is exactly as reviewed (composite enrolment keys, cascade only)');
select th914b_test.ok(
  not exists (
    select 1 from pg_catalog.pg_constraint as k
    join pg_catalog.pg_class as fc on fc.oid = k.confrelid
    where k.contype = 'f'
      and k.conrelid in (select oid from pg_catalog.pg_class
                         where relnamespace = 'public'::regnamespace
                           and relname in ('observations', 'programme_entries', 'rescue_events',
                                           'lesson_progress', 'programme_reminders',
                                           'notification_preferences', 'wellbeing_baseline'))
      and (k.confrelid not in ('public.enrolments'::regclass, 'auth.users'::regclass)
           or k.confupdtype <> 'a' or k.confdeltype <> 'c' or k.confmatchtype <> 's')),
  'catalogue: the seven tables reference only enrolments and auth.users (no consent, consent document, sync or care table), with on delete cascade, match simple, nothing set null or a default');
select th914b_test.ok(
  (select string_agg(indexdef, ' | ' order by indexname)
   from pg_catalog.pg_indexes
   where schemaname = 'public'
     and tablename in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'CREATE UNIQUE INDEX lesson_progress_pkey ON public.lesson_progress USING btree (enrolment_id, lesson_id) | '
  'CREATE INDEX lesson_progress_user_idx ON public.lesson_progress USING btree (user_id) | '
  'CREATE UNIQUE INDEX notification_preferences_pkey ON public.notification_preferences USING btree (user_id) | '
  'CREATE UNIQUE INDEX observations_pkey ON public.observations USING btree (id) | '
  'CREATE UNIQUE INDEX observations_submission_key ON public.observations USING btree (enrolment_id, submission_id, metric) | '
  'CREATE INDEX observations_user_idx ON public.observations USING btree (user_id) | '
  'CREATE UNIQUE INDEX programme_entries_pkey ON public.programme_entries USING btree (id) | '
  'CREATE UNIQUE INDEX programme_entries_submission_key ON public.programme_entries USING btree (enrolment_id, submission_id) | '
  'CREATE INDEX programme_entries_user_idx ON public.programme_entries USING btree (user_id) | '
  'CREATE UNIQUE INDEX programme_reminders_pkey ON public.programme_reminders USING btree (enrolment_id) | '
  'CREATE INDEX programme_reminders_user_idx ON public.programme_reminders USING btree (user_id) | '
  'CREATE INDEX rescue_events_enrolment_idx ON public.rescue_events USING btree (enrolment_id) | '
  'CREATE UNIQUE INDEX rescue_events_pkey ON public.rescue_events USING btree (id) | '
  'CREATE UNIQUE INDEX rescue_events_submission_key ON public.rescue_events USING btree (user_id, submission_id) | '
  'CREATE UNIQUE INDEX wellbeing_baseline_pkey ON public.wellbeing_baseline USING btree (user_id)',
  'catalogue: exactly the reviewed indexes');
select th914b_test.ok(
  (select pg_catalog.pg_get_constraintdef(k.oid) = 'UNIQUE (id, user_id, programme_code)'
   from pg_catalog.pg_constraint as k
   where k.conrelid = 'public.enrolments'::regclass and k.conname = 'enrolments_id_user_programme_key'),
  'catalogue: enrolments has the unique key (id, user_id, programme_code) the composite foreign keys use');
select th914b_test.ok(
  (with t as (
     select oid, relname from pg_catalog.pg_class
     where relnamespace = 'public'::regnamespace
       and relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline'))
   select string_agg(e, ',' order by e collate "C")
   from (select t.relname || ':' || a.privilege_type as e
         from t join pg_catalog.pg_class as c on c.oid = t.oid
         cross join lateral pg_catalog.aclexplode(c.relacl) as a
         where a.grantee = 'authenticated'::regrole
         union all
         select t.relname || '.' || att.attname || ':' || a.privilege_type
         from t join pg_catalog.pg_attribute as att on att.attrelid = t.oid and att.attacl is not null
         cross join lateral pg_catalog.aclexplode(att.attacl) as a
         where a.grantee = 'authenticated'::regrole) as x) =
  'lesson_progress.enrolment_id:INSERT,lesson_progress.lesson_id:INSERT,'
  'lesson_progress.programme_code:INSERT,lesson_progress.user_id:INSERT,lesson_progress:SELECT,'
  'notification_preferences.quiet_hours_enabled:INSERT,notification_preferences.quiet_hours_enabled:UPDATE,'
  'notification_preferences.reminders_enabled:INSERT,notification_preferences.reminders_enabled:UPDATE,'
  'notification_preferences.sensitive_details:INSERT,notification_preferences.sensitive_details:UPDATE,'
  'notification_preferences.user_id:INSERT,notification_preferences:SELECT,'
  'observations.attributes:INSERT,observations.effective_at:INSERT,observations.enrolment_id:INSERT,'
  'observations.metric:INSERT,observations.programme_code:INSERT,observations.submission_id:INSERT,'
  'observations.unit_ucum:INSERT,observations.user_id:INSERT,observations.value:INSERT,observations:SELECT,'
  'programme_entries.enrolment_id:INSERT,programme_entries.kind:INSERT,programme_entries.occurred_at:INSERT,'
  'programme_entries.payload:INSERT,programme_entries.programme_code:INSERT,'
  'programme_entries.submission_id:INSERT,programme_entries.user_id:INSERT,programme_entries:SELECT,'
  'programme_reminders.enrolment_id:INSERT,programme_reminders.programme_code:INSERT,'
  'programme_reminders.remind_at:INSERT,programme_reminders.remind_at:UPDATE,'
  'programme_reminders.user_id:INSERT,programme_reminders:SELECT,'
  'rescue_events.enrolment_id:INSERT,rescue_events.escalated:INSERT,rescue_events.helped:INSERT,'
  'rescue_events.intensity_after:INSERT,rescue_events.intensity_before:INSERT,rescue_events.opened_at:INSERT,'
  'rescue_events.programme_code:INSERT,rescue_events.submission_id:INSERT,rescue_events.tool:INSERT,'
  'rescue_events.user_id:INSERT,rescue_events:SELECT,'
  'wellbeing_baseline.age_range:INSERT,wellbeing_baseline.age_range:UPDATE,'
  'wellbeing_baseline.sleep_band:INSERT,wellbeing_baseline.sleep_band:UPDATE,'
  'wellbeing_baseline.stress_band:INSERT,wellbeing_baseline.stress_band:UPDATE,'
  'wellbeing_baseline.user_id:INSERT,wellbeing_baseline:SELECT',
  'catalogue: authenticated holds exactly the reviewed table and column privileges (no delete, no truncate)');
select th914b_test.ok(
  not exists (
    select 1 from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(c.relacl) as a
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                        'programme_reminders', 'notification_preferences', 'wellbeing_baseline')
      and a.grantee not in (c.relowner, 'authenticated'::regrole))
  and not exists (
    select 1 from pg_catalog.pg_attribute as att
    join pg_catalog.pg_class as c on c.oid = att.attrelid
    cross join lateral pg_catalog.aclexplode(att.attacl) as a
    where c.relnamespace = 'public'::regnamespace and att.attacl is not null
      and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                        'programme_reminders', 'notification_preferences', 'wellbeing_baseline')
      and a.grantee not in (c.relowner, 'authenticated'::regrole))
  and not exists (
    select 1 from pg_catalog.pg_class as c
    cross join pg_catalog.unnest(array['anon', 'authenticated', 'service_role', 'thsync']) as r(n)
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress')
      and pg_catalog.has_table_privilege(r.n, c.oid, 'TRUNCATE')),
  'catalogue: no privilege on the seven tables for anyone but their owner and authenticated (none for anon, service_role, thsync or PUBLIC); no one but the owner may truncate the guarded four');
select th914b_test.ok(
  (select string_agg(tablename || ':' || policyname || ':' || cmd || ':' || permissive || ':'
                     || array_to_string(roles, '+'), ',' order by tablename, policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public'
     and tablename in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'lesson_progress:lesson_progress_insert_own:INSERT:PERMISSIVE:authenticated,'
  'lesson_progress:lesson_progress_select_own:SELECT:PERMISSIVE:authenticated,'
  'notification_preferences:notification_preferences_insert_own:INSERT:PERMISSIVE:authenticated,'
  'notification_preferences:notification_preferences_select_own:SELECT:PERMISSIVE:authenticated,'
  'notification_preferences:notification_preferences_update_own:UPDATE:PERMISSIVE:authenticated,'
  'observations:observations_insert_own:INSERT:PERMISSIVE:authenticated,'
  'observations:observations_select_own:SELECT:PERMISSIVE:authenticated,'
  'programme_entries:programme_entries_insert_own:INSERT:PERMISSIVE:authenticated,'
  'programme_entries:programme_entries_select_own:SELECT:PERMISSIVE:authenticated,'
  'programme_reminders:programme_reminders_insert_own:INSERT:PERMISSIVE:authenticated,'
  'programme_reminders:programme_reminders_select_own:SELECT:PERMISSIVE:authenticated,'
  'programme_reminders:programme_reminders_update_own:UPDATE:PERMISSIVE:authenticated,'
  'rescue_events:rescue_events_insert_own:INSERT:PERMISSIVE:authenticated,'
  'rescue_events:rescue_events_select_own:SELECT:PERMISSIVE:authenticated,'
  'wellbeing_baseline:wellbeing_baseline_insert_own:INSERT:PERMISSIVE:authenticated,'
  'wellbeing_baseline:wellbeing_baseline_select_own:SELECT:PERMISSIVE:authenticated,'
  'wellbeing_baseline:wellbeing_baseline_update_own:UPDATE:PERMISSIVE:authenticated',
  'catalogue: the policies are exactly the reviewed per-command policies for authenticated (seven inserts, three updates, seven selects, no delete)');
select th914b_test.ok(
  (select string_agg(policyname || '=' || regexp_replace(coalesce(with_check, qual), '(public\.)', '', 'g'),
                     ' | ' order by policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public' and cmd = 'INSERT'
     and tablename in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'lesson_progress_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND has_consent(enrolment_id, ''core''::text) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'notification_preferences_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'observations_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND has_consent(enrolment_id, ''core''::text) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'programme_entries_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND has_consent(enrolment_id, ''core''::text) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'programme_reminders_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND has_consent(enrolment_id, ''core''::text) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'rescue_events_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND ((enrolment_id IS NULL) OR has_consent(enrolment_id, ''core''::text)) AND deletion_barrier_open() AND (NOT sync_writer_session())) | '
  'wellbeing_baseline_insert_own=((( SELECT auth.uid() AS uid) = user_id) AND deletion_barrier_open() AND (NOT sync_writer_session()))',
  'catalogue: inserts check ownership, a live core consent for programme rows (none for a shared rescue), the deletion barrier, then the sync guard');
select th914b_test.ok(
  (select string_agg(policyname || ': using ' || coalesce(regexp_replace(qual, '(public\.)', '', 'g'), 'NULL')
                     || ' check ' || coalesce(regexp_replace(with_check, '(public\.)', '', 'g'), 'NULL'),
                     ' | ' order by policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public' and cmd = 'UPDATE'
     and tablename in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'notification_preferences_update_own: using ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session())) check ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session())) | '
  'programme_reminders_update_own: using ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session())) check ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session())) | '
  'wellbeing_baseline_update_own: using ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session())) check ((( SELECT auth.uid() AS uid) = user_id) AND (NOT sync_writer_session()))'
  and (select string_agg(policyname || ': using ' || coalesce(qual, 'NULL') || ' check ' || coalesce(with_check, 'NULL'),
                         ' | ' order by policyname)
       from pg_catalog.pg_policies
       where schemaname = 'public' and cmd = 'SELECT'
         and tablename in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                           'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  (select string_agg(t || '_select_own: using (( SELECT auth.uid() AS uid) = user_id) check NULL', ' | ' order by t)
   from pg_catalog.unnest(array['lesson_progress', 'notification_preferences', 'observations', 'programme_entries',
                                'programme_reminders', 'rescue_events', 'wellbeing_baseline']) as x(t)),
  'catalogue: updates touch own rows only and end with the sync guard (no barrier); reads are own rows, unguarded');
select th914b_test.ok(
  (select string_agg(p.proname || ':' || p.prosecdef || ':' || coalesce(array_to_string(p.proconfig, ';'), '')
                     || ':' || replace(coalesce(p.proacl::text, 'default'), pg_catalog.pg_get_userbyid(p.proowner), 'OWNER'),
                     ',' order by p.proname)
   from pg_catalog.pg_proc as p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('programme_entries_check_payload', 'observations_check_attributes',
                       'programme_records_append_only', 'programme_records_truncate_guard')) =
  'observations_check_attributes:false:search_path="":{OWNER=X/OWNER},'
  'programme_entries_check_payload:false:search_path="":{OWNER=X/OWNER},'
  'programme_records_append_only:false:search_path="":{OWNER=X/OWNER},'
  'programme_records_truncate_guard:false:search_path="":{OWNER=X/OWNER}',
  'catalogue: the four new functions are invoker, have an empty search_path and are executable by their owner only');
select th914b_test.ok(
  (select string_agg(c.relname || ':' || t.tgname || ':' || t.tgtype || ':' || p.proname || ':'
                     || t.tgenabled::text, ',' order by c.relname, t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_class as c on c.oid = t.tgrelid
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where not t.tgisinternal and c.relnamespace = 'public'::regnamespace
     and c.relname in ('observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                       'programme_reminders', 'notification_preferences', 'wellbeing_baseline')) =
  'lesson_progress:lesson_progress_append_only:19:programme_records_append_only:O,'
  'lesson_progress:lesson_progress_truncate_guard:34:programme_records_truncate_guard:A,'
  'notification_preferences:notification_preferences_set_updated_at:19:set_updated_at:O,'
  'observations:observations_append_only:19:programme_records_append_only:O,'
  'observations:observations_check_attributes:7:observations_check_attributes:O,'
  'observations:observations_truncate_guard:34:programme_records_truncate_guard:A,'
  'programme_entries:programme_entries_append_only:19:programme_records_append_only:O,'
  'programme_entries:programme_entries_check_payload:7:programme_entries_check_payload:O,'
  'programme_entries:programme_entries_truncate_guard:34:programme_records_truncate_guard:A,'
  'programme_reminders:programme_reminders_set_updated_at:19:set_updated_at:O,'
  'rescue_events:rescue_events_append_only:19:programme_records_append_only:O,'
  'rescue_events:rescue_events_truncate_guard:34:programme_records_truncate_guard:A,'
  'wellbeing_baseline:wellbeing_baseline_set_updated_at:19:set_updated_at:O',
  'catalogue: triggers exactly as reviewed; the four truncate guards fire in every session mode (tgenabled A)');
select th914b_test.ok(
  not pg_catalog.has_function_privilege('authenticated', 'public.delete_my_app_data(text)', 'EXECUTE')
  and pg_catalog.obj_description('public.delete_my_app_data(text)'::regprocedure, 'pg_proc')
      = 'Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.'
  and (select prosecdef and proconfig = array['search_path=""']
       from pg_catalog.pg_proc where oid = 'public.delete_my_app_data(text)'::regprocedure),
  'catalogue: delete_my_app_data is still owner-only, security definer, with its comment unchanged');
select th914b_test.ok(
  (select string_agg(a.grantee::regrole::text || ':' || a.privilege_type, ',' order by a.grantee::regrole::text)
   from pg_catalog.pg_proc as p
   cross join lateral pg_catalog.aclexplode(coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) as a
   where p.oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure)
  = (select string_agg(x, ',' order by x)
     from pg_catalog.unnest(array[
       (select pg_catalog.pg_get_userbyid(proowner) from pg_catalog.pg_proc
        where oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure) || ':EXECUTE',
       'authenticated:EXECUTE']) as x)
  and (select p.prosecdef and p.proconfig = array['search_path=""']
         and p.proowner = (select proowner from pg_catalog.pg_proc
                           where oid = 'public.delete_my_account(text)'::regprocedure)
       from pg_catalog.pg_proc as p where p.oid = 'public.delete_enrolment_now(uuid,text)'::regprocedure),
  'catalogue: delete_enrolment_now is still executable by its owner and authenticated only, security definer, owned like delete_my_account');

-- Synthetic members (as the superuser) ----------------------------------------------------
insert into public.care_orgs (name) values ('Synthetic Clinic 914b');
select set_config('th914b.org', id::text, true) from public.care_orgs where name = 'Synthetic Clinic 914b';
select th914b_test.seed('00000000-0000-4000-8000-00000914b0a1', 'a',
  array['bf', 'hw', 'st', 're', 'ca', 'ea', 'sd', 'sf', 'ck', 'be'], true, th914b_test.v('org')::uuid);
select th914b_test.seed('00000000-0000-4000-8000-00000914b0b1', 'b', array['hw', 'st', 'bf'], false, null);
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;

-- Valid inserts: every kind and every metric -------------------------------------------------
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0a1'));
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'bp_systolic', 'mm[Hg]', '128'), 1, 'A API: bp_systolic (hw, mm[Hg])');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'bp_diastolic', 'mm[Hg]', '82'), 1, 'A API: bp_diastolic (hw, mm[Hg])');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '64'), 1, 'A API: heart_rate (hw, /min)');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'chol_total', 'mg/dL', '190'), 1, 'A API: chol_total (hw, mg/dL)');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'chol_ldl', 'mg/dL', '110'), 1, 'A API: chol_ldl (hw, mg/dL)');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'chol_hdl', 'mg/dL', '55.5'), 1, 'A API: chol_hdl (hw, mg/dL)');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'triglycerides', 'mg/dL', '140'), 1, 'A API: triglycerides (hw, mg/dL)');
select th914b_test.affects(th914b_test.obs_sql('a_st', 'glucose', 'mg/dL', '105',
  '{"timing": "fasting", "feelings": ["tired", "shaky"], "note": "Synthetic note"}'), 1,
  'A API: glucose (st, mg/dL) with timing, feelings and a note');
select th914b_test.affects(th914b_test.obs_sql('a_st', 'a1c', '%', '6.4'), 1, 'A API: a1c (st, %)');
select th914b_test.affects(th914b_test.obs_sql('a_re', 'egfr', 'mL/min/{1.73_m2}', '88'), 1, 'A API: egfr (re, mL/min/{1.73_m2})');
select th914b_test.affects(th914b_test.obs_sql('a_re', 'urine_acr', 'mg/g', '12'), 1, 'A API: urine_acr (re, mg/g)');
select th914b_test.affects(th914b_test.obs_sql('a_re', 'alt', 'U/L', '25'), 1, 'A API: alt (re, U/L)');
select th914b_test.affects(th914b_test.obs_sql('a_ca', 'peak_flow', 'L/min', '420'), 1, 'A API: peak_flow (ca, L/min)');
select th914b_test.affects(th914b_test.entry_sql('a_hw', 'checkin',
  '{"feel": "good", "stress": "some", "answer": "yes"}'), 1, 'A API: checkin (hw)');
select th914b_test.affects(th914b_test.entry_sql('a_ca', 'ca.zone_check', '{"zone": "green", "symptoms": ["cough"]}'), 1,
  'A API: ca.zone_check');
select th914b_test.affects(th914b_test.entry_sql('a_ca', 'ca.symptom',
  '{"symptoms": ["cough", "wheeze"], "severity": "mild", "triggers": ["pollen"], "note": "Synthetic note"}'), 1,
  'A API: ca.symptom');
select th914b_test.affects(th914b_test.entry_sql('a_ea', 'ea.mood', '{"mood": "okay", "topics": ["sleep"]}'), 1,
  'A API: ea.mood');
select th914b_test.affects(th914b_test.entry_sql('a_ea', 'ea.check_back', '{"change": "better", "reached_out": "friend"}'), 1,
  'A API: ea.check_back');
select th914b_test.affects(th914b_test.entry_sql('a_sd', 'sd.session', '{"settings": ["seated"]}'), 1, 'A API: sd.session');
select th914b_test.affects(th914b_test.entry_sql('a_sd', 'sd.fall', '{}'), 1, 'A API: sd.fall (no keys)');
select th914b_test.affects(th914b_test.entry_sql('a_sf', 'sf.pause', '{"reason": "boredom"}'), 1, 'A API: sf.pause');
select th914b_test.affects(th914b_test.entry_sql('a_ck', 'ck.done',
  '{"item": "flu_shot", "done_on": "2026-10-01", "place": "Synthetic Clinic"}'), 1, 'A API: ck.done');
select th914b_test.affects(th914b_test.entry_sql('a_be', 'be.diary', '{"fatigue": 4, "symptoms": ["nausea"]}'), 1,
  'A API: be.diary');
select th914b_test.affects(th914b_test.entry_sql('a_be', 'be.survivorship', '{"feeling": "hopeful"}'), 1,
  'A API: be.survivorship');
select th914b_test.affects(th914b_test.entry_sql('a_st', 'checkin', '{"feel": "low"}'), 1, 'A API: checkin (st)');
select th914b_test.affects(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at, intensity_before, intensity_after, helped, escalated)
   values (auth.uid(), ''00000000-0000-4000-8000-0000000914c1'', ''breathing'', now(), 7, 3, ''a_little'', false)', 1,
  'A API: an account-level rescue (no enrolment, no consent needed)');
select th914b_test.affects(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''bf'', ''00000000-0000-4000-8000-0000000914c2'', ''urge_surf'', now())',
  th914b_test.v('a_bf')), 1, 'A API: a BreatheFree rescue');
select th914b_test.affects(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-1'')',
  th914b_test.v('a_hw')), 1, 'A API: lesson progress (hw)');
select th914b_test.affects(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-2'')',
  th914b_test.v('a_hw')), 1, 'A API: a second Heartwise lesson');
select th914b_test.affects(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''st'', ''st_basics_1'')',
  th914b_test.v('a_st')), 1, 'A API: lesson progress (st)');
select th914b_test.affects(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''hw'', ''08:30'')',
  th914b_test.v('a_hw')), 1, 'A API: a Heartwise reminder time');
select th914b_test.affects(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''st'', ''20:00'')',
  th914b_test.v('a_st')), 1, 'A API: a Steady reminder time');
select th914b_test.affects(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''re'', ''12:00'')',
  th914b_test.v('a_re')), 1, 'A API: a Renew reminder time');
select th914b_test.affects(
  'insert into public.notification_preferences (user_id, reminders_enabled, sensitive_details, quiet_hours_enabled)
   values (auth.uid(), true, false, true)', 1, 'A API: notification preferences');
select th914b_test.affects(
  'insert into public.wellbeing_baseline (user_id, age_range, sleep_band, stress_band)
   values (auth.uid(), ''35_44'', ''7_8'', ''some'')', 1, 'A API: wellbeing baseline');
select th914b_test.ok(
  (select count(*) from public.observations) = 13 and (select count(*) from public.programme_entries) = 12
  and (select count(*) from public.rescue_events) = 2 and (select count(*) from public.lesson_progress) = 3
  and (select count(*) from public.programme_reminders) = 3
  and (select count(*) from public.notification_preferences) = 1
  and (select count(*) from public.wellbeing_baseline) = 1,
  'A API: A reads back exactly its own rows');

-- Updates and deletes by the member --------------------------------------------------------
select th914b_test.affects(pg_catalog.format(
  'update public.programme_reminders set remind_at = ''09:00'' where enrolment_id = %L', th914b_test.v('a_hw')), 1,
  'A API: changes its Heartwise reminder time');
select th914b_test.affects('update public.notification_preferences set quiet_hours_enabled = false', 1,
  'A API: changes its notification preferences');
select th914b_test.affects('update public.wellbeing_baseline set stress_band = ''low''', 1,
  'A API: changes its wellbeing baseline');
do $member_writes$
declare
  t text;
begin
  foreach t in array array['observations', 'programme_entries', 'rescue_events', 'lesson_progress'] loop
    perform th914b_test.refused(pg_catalog.format('update public.%I set user_id = user_id', t),
      '42501', '%permission denied%', 'A API: no update of ' || t);
  end loop;
  foreach t in array array['observations', 'programme_entries', 'rescue_events', 'lesson_progress',
                           'programme_reminders', 'notification_preferences', 'wellbeing_baseline'] loop
    perform th914b_test.refused(pg_catalog.format('delete from public.%I', t),
      '42501', '%permission denied%', 'A API: no delete on ' || t);
  end loop;
end;
$member_writes$;

-- Payload and attribute checks (23514) ---------------------------------------------------------
select set_config('th914b.a_rows', th914b_test.counts('00000000-0000-4000-8000-00000914b0a1')::text, true);
do $payloads$
declare
  c record;
begin
  for c in select * from (values
    ('checkin', 'a_hw', '{"feel": "good", "extra": "x"}', 'a key outside the list'),
    ('checkin', 'a_hw', '{}', 'none of feel, stress and answer'),
    ('checkin', 'a_hw', '{"feel": 3}', 'a number for a code'),
    ('checkin', 'a_hw', pg_catalog.jsonb_build_object('feel', pg_catalog.repeat('a', 41))::text, 'a code of 41 characters'),
    ('checkin', 'a_hw', '{"feel": "Good"}', 'an upper-case code'),
    ('checkin', 'a_hw', '[]', 'an array instead of an object'),
    ('ca.zone_check', 'a_ca', '{"zone": "green", "extra": "x"}', 'a key outside the list'),
    ('ca.zone_check', 'a_ca', '{"symptoms": ["cough"]}', 'no zone'),
    ('ca.zone_check', 'a_ca', '{"zone": ["green"]}', 'an array for a code'),
    ('ca.zone_check', 'a_ca', '{"zone": "green", "symptoms": ["cough", "cough"]}', 'repeated codes'),
    ('ca.zone_check', 'a_ca', pg_catalog.jsonb_build_object('zone', 'green', 'symptoms',
       (select pg_catalog.jsonb_agg('s' || i) from pg_catalog.generate_series(1, 13) as i))::text, '13 codes'),
    ('ca.symptom', 'a_ca', '{"symptoms": ["cough"], "extra": "x"}', 'a key outside the list'),
    ('ca.symptom', 'a_ca', '{"severity": "mild"}', 'no symptoms'),
    ('ca.symptom', 'a_ca', '{"symptoms": "cough"}', 'a string for codes'),
    ('ca.symptom', 'a_ca', pg_catalog.jsonb_build_object('symptoms', '["cough"]'::jsonb, 'note', pg_catalog.repeat('x', 501))::text,
     'a note of 501 characters'),
    ('ca.symptom', 'a_ca', '{"symptoms": ["cough"], "note": " padded"}', 'a note that is not trimmed'),
    ('ca.symptom', 'a_ca', '{"symptoms": ["cough"], "note": ""}', 'an empty note'),
    ('ea.mood', 'a_ea', '{"mood": "okay", "extra": "x"}', 'a key outside the list'),
    ('ea.mood', 'a_ea', '{"topics": ["sleep"]}', 'no mood'),
    ('ea.mood', 'a_ea', '{"mood": true}', 'a boolean for a code'),
    ('ea.mood', 'a_ea', pg_catalog.jsonb_build_object('mood', pg_catalog.repeat('a', 41))::text, 'a code of 41 characters'),
    ('ea.check_back', 'a_ea', '{"change": "better", "extra": "x"}', 'a key outside the list'),
    ('ea.check_back', 'a_ea', '{"reached_out": "friend"}', 'no change'),
    ('ea.check_back', 'a_ea', '{"change": "better", "reached_out": null}', 'a null for a code'),
    ('ea.check_back', 'a_ea', pg_catalog.jsonb_build_object('change', pg_catalog.repeat('a', 41))::text, 'a code of 41 characters'),
    ('sd.session', 'a_sd', '{"settings": ["seated"], "extra": "x"}', 'a key outside the list'),
    ('sd.session', 'a_sd', '{"settings": "seated"}', 'a string for codes'),
    ('sd.session', 'a_sd', pg_catalog.jsonb_build_object('settings', pg_catalog.jsonb_build_array(pg_catalog.repeat('a', 41)))::text,
     'a code of 41 characters in codes'),
    ('sd.fall', 'a_sd', '{"note": "x"}', 'any key'),
    ('sf.pause', 'a_sf', '{"reason": "boredom", "extra": "x"}', 'a key outside the list'),
    ('sf.pause', 'a_sf', '{}', 'no reason'),
    ('sf.pause', 'a_sf', '{"reason": 1}', 'a number for a code'),
    ('sf.pause', 'a_sf', pg_catalog.jsonb_build_object('reason', pg_catalog.repeat('a', 41))::text, 'a code of 41 characters'),
    ('ck.done', 'a_ck', '{"item": "flu_shot", "done_on": "2026-10-01", "extra": "x"}', 'a key outside the list'),
    ('ck.done', 'a_ck', '{"item": "flu_shot"}', 'no done_on'),
    ('ck.done', 'a_ck', '{"done_on": "2026-10-01"}', 'no item'),
    ('ck.done', 'a_ck', '{"item": "flu_shot", "done_on": "2026-02-30"}', 'a date that does not exist'),
    ('ck.done', 'a_ck', '{"item": "flu_shot", "done_on": "01/10/2026"}', 'a date not in YYYY-MM-DD'),
    ('ck.done', 'a_ck', pg_catalog.jsonb_build_object('item', 'flu_shot', 'done_on', '2026-10-01',
       'place', pg_catalog.repeat('x', 501))::text, 'a place of 501 characters'),
    ('be.diary', 'a_be', '{"fatigue": 4, "extra": "x"}', 'a key outside the list'),
    ('be.diary', 'a_be', '{"symptoms": ["nausea"]}', 'no fatigue'),
    ('be.diary', 'a_be', '{"fatigue": "4"}', 'a string for a score'),
    ('be.diary', 'a_be', '{"fatigue": 11}', 'a score above 10'),
    ('be.diary', 'a_be', '{"fatigue": 4.5}', 'a score that is not an integer'),
    ('be.diary', 'a_be', pg_catalog.jsonb_build_object('fatigue', 4, 'symptoms',
       pg_catalog.jsonb_build_array(pg_catalog.repeat('a', 41)))::text, 'a code of 41 characters in codes'),
    ('be.survivorship', 'a_be', '{"feeling": "hopeful", "extra": "x"}', 'a key outside the list'),
    ('be.survivorship', 'a_be', '{}', 'no feeling'),
    ('be.survivorship', 'a_be', '{"feeling": ["hopeful"]}', 'an array for a code'),
    ('be.survivorship', 'a_be', pg_catalog.jsonb_build_object('feeling', pg_catalog.repeat('a', 41))::text, 'a code of 41 characters')
  ) as t(kind, ekey, payload, what) loop
    perform th914b_test.refused(th914b_test.entry_sql(c.ekey, c.kind, c.payload),
      '23514', 'Programme entry payload is not valid for its kind', 'A API: ' || c.kind || ': ' || c.what);
  end loop;
  for c in select * from (values
    ('glucose', 'a_st', 'mg/dL', '{"timing": "fasting", "extra": "x"}', 'a key outside the list'),
    ('glucose', 'a_st', 'mg/dL', '{"timing": 1}', 'a number for a code'),
    ('glucose', 'a_st', 'mg/dL', '{"feelings": "tired"}', 'a string for codes'),
    ('glucose', 'a_st', 'mg/dL', '{"feelings": ["tired", "tired"]}', 'repeated codes'),
    ('glucose', 'a_st', 'mg/dL', pg_catalog.jsonb_build_object('note', pg_catalog.repeat('x', 501))::text, 'a note of 501 characters'),
    ('glucose', 'a_st', 'mg/dL', '[]', 'an array instead of an object'),
    ('bp_systolic', 'a_hw', 'mm[Hg]', '{"note": "x"}', 'any attribute'),
    ('bp_diastolic', 'a_hw', 'mm[Hg]', '{"note": "x"}', 'any attribute'),
    ('heart_rate', 'a_hw', '/min', '{"note": "x"}', 'any attribute'),
    ('chol_total', 'a_hw', 'mg/dL', '{"note": "x"}', 'any attribute'),
    ('chol_ldl', 'a_hw', 'mg/dL', '{"note": "x"}', 'any attribute'),
    ('chol_hdl', 'a_hw', 'mg/dL', '{"note": "x"}', 'any attribute'),
    ('triglycerides', 'a_hw', 'mg/dL', '{"note": "x"}', 'any attribute'),
    ('a1c', 'a_st', '%', '{"timing": "fasting"}', 'a glucose attribute'),
    ('egfr', 'a_re', 'mL/min/{1.73_m2}', '{"note": "x"}', 'any attribute'),
    ('urine_acr', 'a_re', 'mg/g', '{"note": "x"}', 'any attribute'),
    ('alt', 'a_re', 'U/L', '{"note": "x"}', 'any attribute'),
    ('peak_flow', 'a_ca', 'L/min', '{"note": "x"}', 'any attribute')
  ) as t(metric, ekey, unit, attributes, what) loop
    perform th914b_test.refused(th914b_test.obs_sql(c.ekey, c.metric, c.unit, '100', c.attributes),
      '23514', 'Observation attributes are not valid for this metric', 'A API: ' || c.metric || ': ' || c.what);
  end loop;
end;
$payloads$;

-- Shape checks (23514) --------------------------------------------------------------------------
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'glucose', 'mg/dL', '100'),
  '23514', '%observations_metric_check%', 'A API: a Steady metric on the Heartwise enrolment is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'bp_systolic', 'mg/dL', '120'),
  '23514', '%observations_metric_check%', 'A API: a metric with the wrong unit is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'weight', 'kg', '80'),
  '23514', '%observations_metric_check%', 'A API: an unknown metric is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '10001'),
  '23514', '%observations_value_check%', 'A API: a value above 10000 is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '-1'),
  '23514', '%observations_value_check%', 'A API: a negative value is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '''NaN'''),
  '23514', '%observations_value_check%', 'A API: NaN is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '60', p_effective => '''1899-12-31''::timestamptz'),
  '23514', '%observations_effective_at_check%', 'A API: a measurement before 1900 is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '60', p_effective => 'now() + interval ''2 days'''),
  '23514', '%observations_effective_at_check%', 'A API: a measurement two days ahead is refused');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'ca.zone_check', '{"zone": "green"}'),
  '23514', '%programme_entries_kind_programme_check%', 'A API: a ClearAir kind on the Heartwise enrolment is refused');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'hw.log', '{}'),
  '23514', '%programme_entries_kind_check%', 'A API: an unknown kind is refused');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'checkin', '{"feel": "good"}', p_occurred => '''1999-12-31''::timestamptz'),
  '23514', '%programme_entries_occurred_at_check%', 'A API: an entry before 2000 is refused');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'checkin', '{"feel": "good"}', p_occurred => 'now() + interval ''10 minutes'''),
  '23514', '%programme_entries_occurred_at_check%', 'A API: an entry ten minutes ahead is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, null, gen_random_uuid(), ''breathing'', now())', th914b_test.v('a_bf')),
  '23514', '%rescue_events_enrolment_check%', 'A API: a rescue naming an enrolment without its programme_code is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''sf'', gen_random_uuid(), ''breathing'', now())', th914b_test.v('a_sf')),
  '23514', '%rescue_events_programme_check%', 'A API: a ScrollFree rescue is refused (only BreatheFree)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''hw'', gen_random_uuid(), ''breathing'', now())', th914b_test.v('a_hw')),
  '23514', '%rescue_events_programme_check%', 'A API: a Heartwise rescue is refused (only BreatheFree)');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at, intensity_before)
   values (auth.uid(), gen_random_uuid(), ''breathing'', now(), 11)',
  '23514', '%rescue_events_intensity_before_check%', 'A API: an intensity above 10 is refused');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at, helped)
   values (auth.uid(), gen_random_uuid(), ''breathing'', now(), ''maybe'')',
  '23514', '%rescue_events_helped_check%', 'A API: an unknown helped value is refused');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at)
   values (auth.uid(), gen_random_uuid(), ''Breathing!'', now())',
  '23514', '%rescue_events_tool_check%', 'A API: a tool that is not a code is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''Intro 1'')',
  th914b_test.v('a_hw')), '23514', '%lesson_progress_lesson_id_check%', 'A API: a lesson id that is not a slug is refused');
select th914b_test.refused('update public.wellbeing_baseline set age_range = ''35-44''',
  '23514', '%wellbeing_baseline_age_range_check%', 'A API: an age range not like 35_44 or 75_plus is refused');
select th914b_test.affects('update public.wellbeing_baseline set age_range = ''75_plus''', 1,
  'A API: an age range like 75_plus is accepted');
select th914b_test.refused('update public.wellbeing_baseline set sleep_band = ''8plus''',
  '23514', '%wellbeing_baseline_sleep_band_check%', 'A API: an unknown sleep band is refused');
select th914b_test.refused('update public.wellbeing_baseline set stress_band = ''extreme''',
  '23514', '%wellbeing_baseline_stress_band_check%', 'A API: an unknown stress band is refused');

-- Cross-programme: the composite key ties the row to its enrolment's programme --------------------
select th914b_test.refused(th914b_test.obs_sql('a_st', 'bp_systolic', 'mm[Hg]', '120', p_code => 'hw'),
  '23503', '%observations_enrolment_fkey%', 'A API: a Heartwise observation naming its own Steady enrolment is refused (23503)');
select th914b_test.refused(th914b_test.entry_sql('a_st', 'checkin', '{"feel": "good"}', p_code => 'hw'),
  '23503', '%programme_entries_enrolment_fkey%', 'A API: a check-in naming its own Steady enrolment as Heartwise is refused (23503)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-2'')',
  th914b_test.v('a_st')), '23503', '%lesson_progress_enrolment_fkey%', 'A API: lesson progress naming the Steady enrolment as Heartwise is refused (23503)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''hw'', ''07:00'')',
  th914b_test.v('a_ca')), '23503', '%programme_reminders_enrolment_fkey%', 'A API: a reminder naming the ClearAir enrolment as Heartwise is refused (23503)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''bf'', gen_random_uuid(), ''breathing'', now())', th914b_test.v('a_hw')),
  '23503', '%rescue_events_enrolment_fkey%', 'A API: a BreatheFree rescue naming the Heartwise enrolment is refused (23503)');

-- Replays of the same submission (23505) ---------------------------------------------------------
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '70',
  p_submission => '00000000-0000-4000-8000-0000000914d1'), 1, 'A API: an observation with a fixed submission id');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '70',
  p_submission => '00000000-0000-4000-8000-0000000914d1'),
  '23505', '%observations_submission_key%', 'A API: its replay is refused (23505)');
select th914b_test.affects(th914b_test.obs_sql('a_hw', 'bp_systolic', 'mm[Hg]', '121',
  p_submission => '00000000-0000-4000-8000-0000000914d1'), 1, 'A API: another metric of the same submission is stored');
select th914b_test.affects(th914b_test.entry_sql('a_ea', 'ea.mood', '{"mood": "okay"}',
  p_submission => '00000000-0000-4000-8000-0000000914d2'), 1, 'A API: an entry with a fixed submission id');
select th914b_test.refused(th914b_test.entry_sql('a_ea', 'ea.mood', '{"mood": "okay"}',
  p_submission => '00000000-0000-4000-8000-0000000914d2'),
  '23505', '%programme_entries_submission_key%', 'A API: its replay is refused (23505)');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at)
   values (auth.uid(), ''00000000-0000-4000-8000-0000000914c1'', ''breathing'', now())',
  '23505', '%rescue_events_submission_key%', 'A API: a rescue replay is refused (23505)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-1'')',
  th914b_test.v('a_hw')), '23505', '%lesson_progress_pkey%', 'A API: a lesson completed again is refused (23505)');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''hw'', ''07:00'')',
  th914b_test.v('a_hw')), '23505', '%programme_reminders_pkey%', 'A API: a second reminder row for an enrolment is refused (23505)');
select th914b_test.refused(
  'insert into public.notification_preferences (user_id) values (auth.uid())',
  '23505', '%notification_preferences_pkey%', 'A API: a second preferences row is refused (23505)');
select th914b_test.refused(
  'insert into public.wellbeing_baseline (user_id) values (auth.uid())',
  '23505', '%wellbeing_baseline_pkey%', 'A API: a second baseline row is refused (23505)');

-- No live core consent, left, revoked core (42501) -------------------------------------------------
select th914b_test.refused(th914b_test.entry_sql('a_nu', 'checkin', '{"feel": "good"}'),
  '42501', '%row-level security%', 'A API: a check-in on an enrolment with no consent is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''nu'', ''nu_1'')',
  th914b_test.v('a_nu')), '42501', '%row-level security%', 'A API: lesson progress on an enrolment with no consent is refused');
select th914b_test.refused(th914b_test.obs_sql('a_nu', 'bp_systolic', 'mm[Hg]', '120', p_code => 'nu'),
  '42501', '%row-level security%', 'A API: an observation on an enrolment with no consent is refused');
select th914b_test.affects(pg_catalog.format(
  'update public.enrolments set status = ''left'' where id = %L', th914b_test.v('a_ea')), 1, 'A API: leaves Ease');
select th914b_test.refused(th914b_test.entry_sql('a_ea', 'ea.mood', '{"mood": "okay"}'),
  '42501', '%row-level security%', 'A API: an Ease entry after leaving is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''ea'', ''07:00'')',
  th914b_test.v('a_ea')), '42501', '%row-level security%', 'A API: an Ease reminder after leaving is refused');
select th914b_test.affects(pg_catalog.format(
  'update public.programme_consents set revoked_at = now() where enrolment_id = %L and purpose = ''core''',
  th914b_test.v('a_sf')), 1, 'A API: revokes the ScrollFree core consent');
select th914b_test.refused(th914b_test.entry_sql('a_sf', 'sf.pause', '{"reason": "boredom"}'),
  '42501', '%row-level security%', 'A API: a ScrollFree entry without a live core consent is refused');
select th914b_test.affects(pg_catalog.format(
  'update public.programme_consents set revoked_at = now() where enrolment_id = %L and purpose = ''core''',
  th914b_test.v('a_bf')), 1, 'A API: revokes the BreatheFree core consent');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''bf'', gen_random_uuid(), ''urge_surf'', now())', th914b_test.v('a_bf')),
  '42501', '%row-level security%', 'A API: a BreatheFree rescue without a live core consent is refused');
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.counts('00000000-0000-4000-8000-00000914b0a1')
  = th914b_test.v('a_rows')::jsonb || pg_catalog.jsonb_build_object(
      'observations', (th914b_test.v('a_rows')::jsonb ->> 'observations')::int + 2,
      'programme_entries', (th914b_test.v('a_rows')::jsonb ->> 'programme_entries')::int + 1),
  'A: every refused insert wrote nothing (only the two observations and the entry of the replay setup were added)');

select set_config('th914b.a_rows', th914b_test.counts('00000000-0000-4000-8000-00000914b0a1')::text, true);

-- B: its own rows, never A's ---------------------------------------------------------------------
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0b1'));
select th914b_test.affects(th914b_test.obs_sql('b_hw', 'bp_systolic', 'mm[Hg]', '118'), 1, 'B API: a Heartwise observation');
select th914b_test.affects(th914b_test.entry_sql('b_hw', 'checkin', '{"stress": "low"}'), 1, 'B API: a Heartwise check-in');
select th914b_test.affects(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at) values (auth.uid(), gen_random_uuid(), ''grounding'', now())',
  1, 'B API: an account-level rescue');
select th914b_test.affects(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''bf'', gen_random_uuid(), ''urge_surf'', now())', th914b_test.v('b_bf')), 1,
  'B API: a BreatheFree rescue');
select th914b_test.affects(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-1'')',
  th914b_test.v('b_hw')), 1, 'B API: lesson progress');
select th914b_test.affects(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''hw'', ''07:15'')',
  th914b_test.v('b_hw')), 1, 'B API: a reminder time');
select th914b_test.affects('insert into public.notification_preferences (user_id) values (auth.uid())', 1,
  'B API: notification preferences');
select th914b_test.affects('insert into public.wellbeing_baseline (user_id) values (auth.uid())', 1,
  'B API: an empty wellbeing baseline');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'bp_systolic', 'mm[Hg]', '120'),
  '42501|23503', '%', 'B API: an observation on A''s enrolment as B is refused');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'bp_systolic', 'mm[Hg]', '120',
  p_user => '00000000-0000-4000-8000-00000914b0a1'),
  '42501', '%row-level security%', 'B API: an observation on A''s enrolment in A''s name is refused');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'checkin', '{"feel": "good"}'),
  '42501|23503', '%', 'B API: a check-in on A''s enrolment is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.intro-9'')',
  th914b_test.v('a_hw')), '42501|23503', '%', 'B API: lesson progress on A''s enrolment is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''st'', ''07:00'')',
  th914b_test.v('a_st')), '42501|23503', '%', 'B API: a reminder on A''s enrolment is refused');
select th914b_test.refused(pg_catalog.format(
  'insert into public.rescue_events (user_id, enrolment_id, programme_code, submission_id, tool, opened_at)
   values (auth.uid(), %L, ''bf'', gen_random_uuid(), ''breathing'', now())', th914b_test.v('a_bf')),
  '42501|23503', '%', 'B API: a rescue on A''s BreatheFree enrolment is refused');
select th914b_test.ok(
  (select count(*) from public.observations where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.programme_entries where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.rescue_events where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.lesson_progress where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.programme_reminders where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.notification_preferences where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.wellbeing_baseline where user_id = '00000000-0000-4000-8000-00000914b0a1') = 0
  and (select count(*) from public.observations) = 1 and (select count(*) from public.programme_entries) = 1
  and (select count(*) from public.rescue_events) = 2 and (select count(*) from public.lesson_progress) = 1
  and (select count(*) from public.programme_reminders) = 1
  and (select count(*) from public.notification_preferences) = 1
  and (select count(*) from public.wellbeing_baseline) = 1,
  'B API: B sees none of A''s rows, only its own');
select th914b_test.affects('update public.notification_preferences set reminders_enabled = true
  where user_id = ''00000000-0000-4000-8000-00000914b0a1''', 0, 'B API: cannot change A''s preferences (no row qualifies)');
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.counts('00000000-0000-4000-8000-00000914b0a1') = th914b_test.v('a_rows')::jsonb,
  'A: nothing was written to or changed in A''s rows by B');

-- Sync session: refused on every insert and update ------------------------------------------------
select th914b_test.act_as('thsync', th914b_test.claims('00000000-0000-4000-8000-00000914b0a1'));
select th914b_test.ok(session_user = 'thsync' and current_user = 'authenticated' and public.sync_writer_session(),
  'sync session: logged in as thsync, acting as authenticated with A''s claims');
select th914b_test.refused(th914b_test.obs_sql('a_hw', 'heart_rate', '/min', '66'),
  '42501', '%row-level security%', 'A sync: cannot insert an observation');
select th914b_test.refused(th914b_test.entry_sql('a_hw', 'checkin', '{"feel": "good"}'),
  '42501', '%row-level security%', 'A sync: cannot insert a programme entry');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at) values (auth.uid(), gen_random_uuid(), ''breathing'', now())',
  '42501', '%row-level security%', 'A sync: cannot insert a rescue event');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''hw'', ''hw.sync'')',
  th914b_test.v('a_hw')), '42501', '%row-level security%', 'A sync: cannot insert lesson progress');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''re'', ''07:00'')',
  th914b_test.v('a_re')), '42501', '%row-level security%', 'A sync: cannot insert a reminder time');
select th914b_test.refused(
  'insert into public.notification_preferences (user_id) values (''00000000-0000-4000-8000-00000914b0c9'')',
  '42501', '%row-level security%', 'A sync: cannot insert notification preferences');
select th914b_test.refused(
  'insert into public.wellbeing_baseline (user_id) values (''00000000-0000-4000-8000-00000914b0c9'')',
  '42501', '%row-level security%', 'A sync: cannot insert a wellbeing baseline');
select th914b_test.affects('update public.programme_reminders set remind_at = ''06:00''', 0,
  'A sync: cannot update a reminder time (no row qualifies)');
select th914b_test.affects('update public.notification_preferences set reminders_enabled = false', 0,
  'A sync: cannot update notification preferences (no row qualifies)');
select th914b_test.affects('update public.wellbeing_baseline set sleep_band = ''lt5''', 0,
  'A sync: cannot update the wellbeing baseline (no row qualifies)');
do $sync_updates$
declare
  t text;
begin
  foreach t in array array['observations', 'programme_entries', 'rescue_events', 'lesson_progress'] loop
    perform th914b_test.refused(pg_catalog.format('update public.%I set user_id = user_id', t),
      '42501', '%permission denied%', 'A sync: cannot update ' || t);
  end loop;
end;
$sync_updates$;
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.counts('00000000-0000-4000-8000-00000914b0a1') = th914b_test.v('a_rows')::jsonb
  and (select remind_at = '09:00' from public.programme_reminders where enrolment_id = th914b_test.v('a_hw')::uuid)
  and (select not quiet_hours_enabled and reminders_enabled from public.notification_preferences
       where user_id = '00000000-0000-4000-8000-00000914b0a1')
  and (select sleep_band = '7_8' from public.wellbeing_baseline where user_id = '00000000-0000-4000-8000-00000914b0a1'),
  'A: the sync session wrote and changed nothing');

-- Append-only and truncate guards, whatever the role --------------------------------------------
do $guards$
declare
  t text;
begin
  foreach t in array array['observations', 'programme_entries', 'rescue_events', 'lesson_progress'] loop
    perform th914b_test.refused(pg_catalog.format('update public.%I set user_id = user_id', t),
      'TH026', 'Programme records are append-only', 'superuser: an update of ' || t || ' is refused (TH026)',
      'programme_records_append_only');
    perform th914b_test.refused(pg_catalog.format('truncate public.%I', t),
      'TH027', 'Programme records are removed only with their programme or account',
      'superuser: truncate public.' || t || ' is refused (TH027)', 'programme_rows_delete_only');
  end loop;
end;
$guards$;
-- A cascade still reaches an older guard first (TH003 or TH019, as before
-- these tables existed).
select th914b_test.refused('truncate public.enrolments cascade', 'TH003|TH019', '%',
  'superuser: truncate public.enrolments cascade is still refused by the first older guard');
select th914b_test.refused('truncate auth.users cascade', 'TH003|TH019', '%',
  'superuser: truncate auth.users cascade is still refused by the first older guard');
select th914b_test.ok(
  th914b_test.counts('00000000-0000-4000-8000-00000914b0a1') = th914b_test.v('a_rows')::jsonb
  and (select count(*) from public.observations where user_id = '00000000-0000-4000-8000-00000914b0b1') = 1
  and (select count(*) from public.enrolments where user_id = '00000000-0000-4000-8000-00000914b0b1') = 3,
  'superuser: every refused update and truncate kept every row');

-- B: delete-now of its BreatheFree enrolment removes its BreatheFree rescue -----------------------
select set_config('th914b.b_before', th914b_test.state('00000000-0000-4000-8000-00000914b0b1')::text, true);
select set_config('th914b.expected', th914b_test.rows_for('00000000-0000-4000-8000-00000914b0b1',
  th914b_test.v('b_bf')::uuid, 'bf')::text, true);
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0b1'));
select set_config('th914b.receipt', public.delete_enrolment_now(th914b_test.v('b_bf')::uuid, 'DELETE')::text, true);
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.v('receipt')::jsonb = th914b_test.v('expected')::jsonb
  and (th914b_test.v('receipt')::jsonb ->> 'rescue_events')::int = 1
  and (select count(*) from pg_catalog.jsonb_object_keys(th914b_test.v('receipt')::jsonb)) = 17,
  'B BreatheFree: delete-now returns 17 counts equal to the rows held, its rescue included');
select th914b_test.ok(
  (select count(*) from public.rescue_events where user_id = '00000000-0000-4000-8000-00000914b0b1') = 1
  and (select count(*) from public.rescue_events where user_id = '00000000-0000-4000-8000-00000914b0b1'
       and enrolment_id is null) = 1
  and th914b_test.state('00000000-0000-4000-8000-00000914b0b1')
      = th914b_test.v('b_before')::jsonb || pg_catalog.jsonb_build_object(
          'enrolments', 2, 'programme_consents', 2, 'rescue_events', 1),
  'B BreatheFree: the BreatheFree rescue is gone; the account-level rescue and every other row stay');

-- A: delete-now of Heartwise --------------------------------------------------------------------
select set_config('th914b.a_before', th914b_test.state('00000000-0000-4000-8000-00000914b0a1')::text, true);
select set_config('th914b.st_before', (
  select pg_catalog.jsonb_build_object(
    'observations', (select count(*) from public.observations where enrolment_id = th914b_test.v('a_st')::uuid),
    'lesson_progress', (select count(*) from public.lesson_progress where enrolment_id = th914b_test.v('a_st')::uuid),
    'programme_reminders', (select count(*) from public.programme_reminders where enrolment_id = th914b_test.v('a_st')::uuid),
    'programme_entries', (select count(*) from public.programme_entries where enrolment_id = th914b_test.v('a_st')::uuid),
    'rescues', (select count(*) from public.rescue_events where user_id = '00000000-0000-4000-8000-00000914b0a1'))::text), true);
select set_config('th914b.expected', th914b_test.rows_for('00000000-0000-4000-8000-00000914b0a1',
  th914b_test.v('a_hw')::uuid, 'hw')::text, true);
select th914b_test.ok(
  th914b_test.v('expected')::jsonb @> '{"enrolments": 1, "observations": 9, "programme_entries": 1,
    "rescue_events": 0, "lesson_progress": 2, "programme_reminders": 1, "program_data": 1,
    "sync_areas": 1}'::jsonb
  and th914b_test.v('st_before')::jsonb = '{"observations": 2, "lesson_progress": 1,
    "programme_reminders": 1, "programme_entries": 1, "rescues": 2}'::jsonb,
  'A Heartwise setup: Heartwise holds observations, an entry, a lesson and a reminder; Steady and the rescues hold their own');
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0a1'));
select set_config('th914b.receipt', public.delete_enrolment_now(th914b_test.v('a_hw')::uuid, 'DELETE')::text, true);
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.v('receipt')::jsonb = th914b_test.v('expected')::jsonb
  and (select count(*) from pg_catalog.jsonb_object_keys(th914b_test.v('receipt')::jsonb)) = 17,
  'A Heartwise: delete-now returns 17 counts equal to the rows held for Heartwise');
select th914b_test.ok(
  not exists (select 1 from pg_catalog.jsonb_each(th914b_test.rows_for('00000000-0000-4000-8000-00000914b0a1',
                th914b_test.v('a_hw')::uuid, 'hw')) as e where e.value <> '0'::jsonb)
  and (select pg_catalog.jsonb_build_object(
    'observations', (select count(*) from public.observations where enrolment_id = th914b_test.v('a_st')::uuid),
    'lesson_progress', (select count(*) from public.lesson_progress where enrolment_id = th914b_test.v('a_st')::uuid),
    'programme_reminders', (select count(*) from public.programme_reminders where enrolment_id = th914b_test.v('a_st')::uuid),
    'programme_entries', (select count(*) from public.programme_entries where enrolment_id = th914b_test.v('a_st')::uuid),
    'rescues', (select count(*) from public.rescue_events where user_id = '00000000-0000-4000-8000-00000914b0a1')))
    = th914b_test.v('st_before')::jsonb,
  'A Heartwise: its records are gone; Steady''s records, the account-level and BreatheFree rescues are kept');
select th914b_test.ok(
  th914b_test.state('00000000-0000-4000-8000-00000914b0a1') = (
    select pg_catalog.jsonb_object_agg(b.key,
      case when r.value is null then b.value
           else pg_catalog.to_jsonb((b.value #>> '{}')::bigint - (r.value #>> '{}')::bigint) end)
    from pg_catalog.jsonb_each(th914b_test.v('a_before')::jsonb) as b
    left join pg_catalog.jsonb_each(th914b_test.v('receipt')::jsonb) as r on r.key = b.key)
  and th914b_test.state('00000000-0000-4000-8000-00000914b0b1') = th914b_test.v('b_before')::jsonb
       || pg_catalog.jsonb_build_object('enrolments', 2, 'programme_consents', 2, 'rescue_events', 1),
  'A Heartwise: nothing else of A changed; B unchanged');

-- A: account deletion -------------------------------------------------------------------------
select set_config('th914b.a_before', th914b_test.counts('00000000-0000-4000-8000-00000914b0a1')::text, true);
select set_config('th914b.b_before', th914b_test.state('00000000-0000-4000-8000-00000914b0b1')::text, true);
select th914b_test.ok(
  (select count(*) = 24 and bool_and((value #>> '{}')::int >= 1)
   from pg_catalog.jsonb_each(th914b_test.v('a_before')::jsonb)),
  'deletion setup: A holds rows in all 24 member tables');
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0a1'));
select th914b_test.ok(public.begin_account_deletion('DELETE'), 'A API: begin_account_deletion sets the barrier');
select th914b_test.refused(th914b_test.obs_sql('a_st', 'a1c', '%', '6.1'),
  '42501', '%row-level security%', 'A API, deletion started: no new observation');
select th914b_test.refused(th914b_test.entry_sql('a_st', 'checkin', '{"feel": "good"}'),
  '42501', '%row-level security%', 'A API, deletion started: no new programme entry');
select th914b_test.refused(
  'insert into public.rescue_events (user_id, submission_id, tool, opened_at) values (auth.uid(), gen_random_uuid(), ''breathing'', now())',
  '42501', '%row-level security%', 'A API, deletion started: no new rescue, even account-level');
select th914b_test.refused(pg_catalog.format(
  'insert into public.lesson_progress (user_id, enrolment_id, programme_code, lesson_id) values (auth.uid(), %L, ''st'', ''st_basics_2'')',
  th914b_test.v('a_st')), '42501', '%row-level security%', 'A API, deletion started: no new lesson progress');
select th914b_test.refused(pg_catalog.format(
  'insert into public.programme_reminders (user_id, enrolment_id, programme_code, remind_at) values (auth.uid(), %L, ''re'', ''07:00'')',
  th914b_test.v('a_re')), '42501', '%row-level security%', 'A API, deletion started: no new reminder time');
select th914b_test.refused('insert into public.notification_preferences (user_id) values (auth.uid())',
  '42501', '%row-level security%', 'A API, deletion started: no new preferences row');
select th914b_test.refused('insert into public.wellbeing_baseline (user_id) values (auth.uid())',
  '42501', '%row-level security%', 'A API, deletion started: no new baseline row');
select set_config('th914b.a_receipt', public.delete_my_account('DELETE')::text, true);
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.v('a_receipt')::jsonb = th914b_test.v('a_before')::jsonb
  and (select count(*) from pg_catalog.jsonb_object_keys(th914b_test.v('a_receipt')::jsonb)) = 24,
  'deletion: delete_my_account returns the 24 counts of the rows A held');
select th914b_test.ok(
  (select bool_and(value = '0'::jsonb)
   from pg_catalog.jsonb_each(th914b_test.state('00000000-0000-4000-8000-00000914b0a1'))),
  'deletion: no row of A is left in any member table, and no identity');
select th914b_test.ok(
  th914b_test.state('00000000-0000-4000-8000-00000914b0b1') = th914b_test.v('b_before')::jsonb,
  'deletion: B is untouched');
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0a1'));
select set_config('th914b.a_repeat', public.delete_my_account('DELETE')::text, true);
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  (select count(*) = 24 and bool_and(value = '0'::jsonb)
   from pg_catalog.jsonb_each(th914b_test.v('a_repeat')::jsonb)),
  'deletion: a repeat returns 24 zero counts');

-- B: delete_my_app_data on its own (owner context, as delete_my_account runs
-- it) deletes and counts every row before any identity delete could cascade.
select th914b_test.act_as('authenticator', th914b_test.claims('00000000-0000-4000-8000-00000914b0b1'));
select th914b_test.ok(public.begin_account_deletion('DELETE'), 'B API: begin_account_deletion sets the barrier');
select th914b_test.act_as(current_setting('th914b.superuser'), th914b_test.claims('00000000-0000-4000-8000-00000914b0b1'));
select set_config('th914b.b_before', th914b_test.counts('00000000-0000-4000-8000-00000914b0b1')::text, true);
select set_config('th914b.b_receipt', public.delete_my_app_data('DELETE')::text, true);
select th914b_test.act_as(current_setting('th914b.superuser'), null);
select th914b_test.ok(
  th914b_test.v('b_receipt')::jsonb = th914b_test.v('b_before')::jsonb
  and th914b_test.v('b_before')::jsonb @> '{"observations": 1, "programme_entries": 1, "rescue_events": 1,
    "lesson_progress": 1, "programme_reminders": 1, "notification_preferences": 1, "wellbeing_baseline": 1}'::jsonb
  and (select bool_and(value = '0'::jsonb)
       from pg_catalog.jsonb_each(th914b_test.counts('00000000-0000-4000-8000-00000914b0b1')))
  and (select count(*) from auth.users where id = '00000000-0000-4000-8000-00000914b0b1') = 1,
  'B owner: delete_my_app_data alone deletes and counts every row of B, a row in each of the seven new tables included; the identity is still there');

select 'TH914B_SQL_TESTS_COMPLETE' as result;
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

-- Synthetic C with one Heartwise enrolment and its core consent.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-00000914b0c1', 'synthetic-control-914b@example.test', 'authenticated', 'authenticated');
insert into public.enrolments (id, user_id, programme_code, status) values
  ('00000000-0000-4000-8000-00000914be01', '00000000-0000-4000-8000-00000914b0c1', 'hw', 'focus');
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale) values
  ('00000000-0000-4000-8000-00000914be01', 'core', 'v1-draft', 'en');

-- As authenticated, C stores a heart-rate observation whose attributes hold
-- a key no metric allows. The outcome is "stored" or the SQLSTATE.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-00000914b0c1', 'role', 'authenticated')::text, true);
set local role authenticated;
do $c$
declare
  outcome text;
begin
  begin
    execute 'insert into public.observations (user_id, enrolment_id, programme_code, submission_id, metric,'
      ' value, unit_ucum, effective_at, attributes) values (''00000000-0000-4000-8000-00000914b0c1'','
      ' ''00000000-0000-4000-8000-00000914be01'', ''hw'', gen_random_uuid(), ''heart_rate'', 60, ''/min'','
      ' now(), ''{"unexpected": "x"}'')';
    outcome := 'stored';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th914bc.outcome', outcome, true);
  raise notice 'CONTROL observation with an unknown attribute key: %', outcome;
end;
$c$;
reset role;
select set_config('request.jwt.claims', '', true);

select case current_setting('th914bc.outcome')
  when '23514' then 'TH914B_CONTROL_UNKNOWN_KEY_REFUSED'
  when '42P01' then 'TH914B_CONTROL_TABLE_ABSENT'
  else 'TH914B_CONTROL_UNEXPECTED'
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
  echo "Programme records check failed: $1" >&2
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

for f in "$migration" "$app_data_source" "$delete_now_source" "$contract"; do
  [[ -f "$f" ]] || fail "missing $f"
done
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

# Name and version: after 202610180012 and used by no other file.
[[ "${migration##*/}" =~ ^[0-9]{12}_[a-z0-9_]+\.sql$ ]] ||
  fail "${migration##*/} is not YYYYMMDDNNNN_name.sql"
[[ "$(find "$migrations_dir" -maxdepth 1 -name '202610180013_*.sql' | wc -l | tr -d ' ')" -eq 1 ]] ||
  fail 'exactly one migration may use version 202610180013'

# The SQL on stdin as one statement per line: comments removed, lower case,
# double quotes dropped, whitespace collapsed to single spaces, split at ";".
statements() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' |
    sed -E 's/ +/ /g' | tr ';' '\n' | sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}
# The migration with every function body replaced by "body", one statement
# per line.
outline=$(awk '
  /^as \$\$$/ { print "as body"; skip = 1; next }
  skip && /^\$\$;$/ { print ";"; skip = 0; next }
  !skip { print }
' "$migration" | statements)

[[ "$(head -n 1 <<<"$outline")" == 'begin' ]] || fail "$migration must start with begin;"
[[ "$(tail -n 1 <<<"$outline")" == 'commit' ]] || fail "$migration must end with commit;"

# The seven tables, each with row-level security enabled and forced and every
# privilege revoked before the reviewed grants.
tables='observations programme_entries rescue_events lesson_progress programme_reminders notification_preferences wellbeing_baseline'
guarded='observations programme_entries rescue_events lesson_progress'
created=$(grep -Eo '^create table public\.[a-z_]+' <<<"$outline" | sed 's/^create table public\.//' | LC_ALL=C sort | tr '\n' ' ')
[[ "$created" == "$(tr ' ' '\n' <<<"$tables" | LC_ALL=C sort | tr '\n' ' ')" ]] ||
  fail "$migration must create exactly the seven programme record tables (got: $created)"
for t in $tables; do
  grep -Fxq "alter table public.$t enable row level security" <<<"$outline" || fail "$t: enable row level security"
  grep -Fxq "alter table public.$t force row level security" <<<"$outline" || fail "$t: force row level security"
  grep -Fxq "revoke all on table public.$t from public, anon, authenticated, service_role" <<<"$outline" ||
    fail "$t: revoke all from public, anon, authenticated and service_role"
done
for c in deletion_audit programme_plans lapse_events record_item_id ' source '; do
  if grep -Fq "$c" <<<"$outline"; then fail "$migration must not add $c"; fi
done

# Never loosen.
if grep -Eq 'grant all|disable row level security|no force row level security|disable trigger|session_replication_role|owner to|(create|alter|drop) role|security_barrier|create (or replace )?(materialized )?view|(^|[^a-z_])drop ' <<<"$outline"; then
  fail 'migration must not grant all, weaken row-level security, disable triggers, change roles or owners, create views or drop anything'
fi
if grep -E '^grant ' <<<"$outline" | grep -Eq '(^|[^a-z_])(anon|service_role|public|thsync)([^a-z_.]|$)'; then
  fail 'nothing is granted to anon, service_role, PUBLIC or thsync'
fi

# Foreign keys: only the member (auth.users) and the composite enrolment key,
# both on delete cascade; nothing on the consent, consent document, sync or
# care tables; no action that rewrites a referencing row.
if grep -Eq 'references public\.(programme_consents|account_consents|consent_documents|sync_[a-z_]+|care_[a-z_]+|caregiver[a-z_]*|supporters)' <<<"$outline"; then
  fail 'no programme record table may reference the consent, consent document, sync or care tables'
fi
if grep -Eq 'set null|set default' <<<"$outline"; then
  fail 'no foreign key may set null or a default'
fi
[[ "$(grep -Eo '(^| )references [a-z_.]+' <<<"$outline" | sed 's/^ //' | LC_ALL=C sort -u | tr '\n' ' ')" == 'references auth.users references public.enrolments ' ]] ||
  fail 'the tables reference only auth.users and public.enrolments'
[[ "$(grep -o 'foreign key (enrolment_id, user_id, programme_code) references public.enrolments (id, user_id, programme_code) on delete cascade' <<<"$outline" | wc -l | tr -d ' ')" -eq 5 &&
  "$(grep -o 'references public\.enrolments' <<<"$outline" | wc -l | tr -d ' ')" -eq 5 ]] ||
  fail 'the five programme tables each reference their enrolment through (enrolment_id, user_id, programme_code), on delete cascade, and nothing else references enrolments'
[[ "$(grep -o 'user_id uuid not null references auth.users(id) on delete cascade' <<<"$outline" | wc -l | tr -d ' ')" -eq 5 &&
  "$(grep -o 'user_id uuid primary key references auth.users(id) on delete cascade' <<<"$outline" | wc -l | tr -d ' ')" -eq 2 &&
  "$(grep -o 'references auth\.users' <<<"$outline" | wc -l | tr -d ' ')" -eq 7 ]] ||
  fail 'every table holds user_id referencing auth.users(id) on delete cascade'

# The only statement on an existing table is the enrolment key.
while IFS= read -r stmt; do
  [[ -n "$stmt" ]] || continue
  [[ "$stmt" == 'alter table public.enrolments add constraint enrolments_id_user_programme_key unique (id, user_id, programme_code)' ]] && continue
  targets=$(sed -nE 's/^alter table public\.([a-z_]+).*/\1/p; s/^create (unique )?index [a-z_]+ on public\.([a-z_]+) .*/\2/p; s/^create trigger [a-z_]+ (before|after) [a-z ]+ on public\.([a-z_]+) .*/\2/p; s/^create policy [a-z_]+ on public\.([a-z_]+) .*/\1/p; s/^comment on (table|column) public\.([a-z_]+).*/\2/p' <<<"$stmt")
  if [[ ! "$stmt" =~ \ on\ function\  && "$stmt" =~ ^(grant|revoke)\ .*\ on\ (table\ )?(public\..*)\ (to|from)\  ]]; then
    targets=$(grep -Eo 'public\.[a-z_]+' <<<"${BASH_REMATCH[3]}" | sed 's/^public\.//')
  fi
  if [[ -z "$targets" && ! "$stmt" =~ ^((grant|revoke)\ .*\ on\ function\ |create\ (or\ replace\ )?function\ |create\ table\ ) ]]; then
    fail "unexpected statement in $migration: $stmt"
  fi
  for t in $targets; do
    grep -Eq "(^| )$t( |\$)" <<<"$tables" || fail "the only statement on an existing table may be the enrolments_id_user_programme_key constraint (got: $stmt)"
  done
done < <(grep -Ev '^(begin|commit)$' <<<"$outline")
grep -Fxq 'alter table public.enrolments add constraint enrolments_id_user_programme_key unique (id, user_id, programme_code)' <<<"$outline" ||
  fail 'enrolments needs the unique key (id, user_id, programme_code) for the composite foreign keys'

# Functions: exactly the four new ones, each invoker, search_path '', revoked
# from public, anon, authenticated and service_role later in the file, never
# granted; and the two deletion functions re-created.
new_functions=$(grep -Eo '^create function public\.[a-z_]+\(\)' "$migration" | sed 's/^create function public\.//' | LC_ALL=C sort | tr '\n' ' ')
[[ "$new_functions" == 'observations_check_attributes() programme_entries_check_payload() programme_records_append_only() programme_records_truncate_guard() ' ]] ||
  fail "$migration must create exactly the four reviewed functions (got: $new_functions)"
[[ "$(grep -Ec '^create (or replace )?function ' "$migration")" -eq 6 ]] || fail 'six function definitions: four new, two re-created'
for name in observations_check_attributes programme_entries_check_payload programme_records_append_only programme_records_truncate_guard; do
  create_at=$(grep -n "^create function public\\.$name() returns trigger language plpgsql security invoker set search_path = '' as body\$" <<<"$outline" | cut -d: -f1 || true)
  revoke_at=$(grep -nFx "revoke all on function public.$name() from public, anon, authenticated, service_role" <<<"$outline" | cut -d: -f1 || true)
  [[ -n "$create_at" && -n "$revoke_at" && "$revoke_at" -gt "$create_at" ]] ||
    fail "$name must be a security invoker trigger function with search_path '' followed by revoke all from public, anon, authenticated and service_role"
done
if grep -Eq '^grant .* on function ' <<<"$outline"; then fail 'no function is granted'; fi
if [[ "$(grep -Ec '^create or replace function ' "$migration")" -ne 2 ]] ||
  ! grep -Fxq 'create or replace function public.delete_my_app_data(p_confirmation text)' "$migration" ||
  ! grep -Fxq 'create or replace function public.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)' "$migration"; then
  fail 'the only functions replaced are delete_my_app_data and delete_enrolment_now'
fi
[[ "$(grep -Ec '^security definer$' "$migration")" -eq 2 ]] ||
  fail 'only the re-created delete_my_app_data and delete_enrolment_now are security definer'
if grep -E '^(grant|revoke|alter function|comment on function)' <<<"$outline" | grep -Eq 'delete_my_app_data|delete_enrolment_now'; then
  fail 'no grant, revoke, alter function or comment on function for delete_my_app_data or delete_enrolment_now (owner, privileges and comment are kept)'
fi
if grep -Eq 'delete_my_account|begin_account_deletion' "$migration"; then
  fail "$migration must not name delete_my_account or begin_account_deletion"
fi

# Grants: exactly the reviewed ones.
grants=$(grep -E '^grant ' <<<"$outline" | LC_ALL=C sort)
expected_grants=$(LC_ALL=C sort <<'GRANTS'
grant select on table public.observations to authenticated
grant insert (user_id, enrolment_id, programme_code, submission_id, metric, value, unit_ucum, effective_at, attributes) on table public.observations to authenticated
grant select on table public.programme_entries to authenticated
grant insert (user_id, enrolment_id, programme_code, submission_id, kind, occurred_at, payload) on table public.programme_entries to authenticated
grant select on table public.rescue_events to authenticated
grant insert (user_id, enrolment_id, programme_code, submission_id, tool, opened_at, intensity_before, intensity_after, helped, escalated) on table public.rescue_events to authenticated
grant select on table public.lesson_progress to authenticated
grant insert (user_id, enrolment_id, programme_code, lesson_id) on table public.lesson_progress to authenticated
grant select on table public.programme_reminders to authenticated
grant insert (user_id, enrolment_id, programme_code, remind_at) on table public.programme_reminders to authenticated
grant update (remind_at) on table public.programme_reminders to authenticated
grant select on table public.notification_preferences to authenticated
grant insert (user_id, reminders_enabled, sensitive_details, quiet_hours_enabled) on table public.notification_preferences to authenticated
grant update (reminders_enabled, sensitive_details, quiet_hours_enabled) on table public.notification_preferences to authenticated
grant select on table public.wellbeing_baseline to authenticated
grant insert (user_id, age_range, sleep_band, stress_band) on table public.wellbeing_baseline to authenticated
grant update (age_range, sleep_band, stress_band) on table public.wellbeing_baseline to authenticated
GRANTS
)
[[ "$grants" == "$expected_grants" ]] || fail "$migration must contain exactly the reviewed grants. Got:
$grants"

# Policies: exactly the reviewed per-command policies. Inserts check
# ownership, a live core consent for programme rows (none for a shared
# rescue), the deletion barrier, then the sync guard; updates have no barrier.
policies=$(grep -E '^create policy ' <<<"$outline" | LC_ALL=C sort)
own="(select auth.uid()) = user_id"
guard="not public.sync_writer_session()"
expected_policies=$(
  for t in $tables; do
    echo "create policy ${t}_select_own on public.$t for select to authenticated using ($own)"
  done
  for t in observations programme_entries lesson_progress programme_reminders; do
    echo "create policy ${t}_insert_own on public.$t for insert to authenticated with check ( $own and public.has_consent(enrolment_id, 'core') and public.deletion_barrier_open() and $guard )"
  done
  echo "create policy rescue_events_insert_own on public.rescue_events for insert to authenticated with check ( $own and (enrolment_id is null or public.has_consent(enrolment_id, 'core')) and public.deletion_barrier_open() and $guard )"
  for t in notification_preferences wellbeing_baseline; do
    echo "create policy ${t}_insert_own on public.$t for insert to authenticated with check ( $own and public.deletion_barrier_open() and $guard )"
  done
  for t in programme_reminders notification_preferences wellbeing_baseline; do
    echo "create policy ${t}_update_own on public.$t for update to authenticated using ($own and $guard) with check ($own and $guard)"
  done
)
expected_policies=$(LC_ALL=C sort <<<"$expected_policies")
[[ "$policies" == "$expected_policies" ]] || fail "$migration must contain exactly the reviewed policies. Got:
$policies"

# Triggers: payload and attribute checks, append-only and truncate guards on
# the four record tables (enabled always), updated_at on the three others.
triggers=$(grep -E '^create trigger ' <<<"$outline" | LC_ALL=C sort)
expected_triggers=$(
  echo 'create trigger programme_entries_check_payload before insert on public.programme_entries for each row execute function public.programme_entries_check_payload()'
  echo 'create trigger observations_check_attributes before insert on public.observations for each row execute function public.observations_check_attributes()'
  for t in $guarded; do
    echo "create trigger ${t}_append_only before update on public.$t for each row execute function public.programme_records_append_only()"
    echo "create trigger ${t}_truncate_guard before truncate on public.$t for each statement execute function public.programme_records_truncate_guard()"
  done
  for t in programme_reminders notification_preferences wellbeing_baseline; do
    echo "create trigger ${t}_set_updated_at before update on public.$t for each row execute function public.set_updated_at()"
  done
)
expected_triggers=$(LC_ALL=C sort <<<"$expected_triggers")
[[ "$triggers" == "$expected_triggers" ]] || fail "$migration must contain exactly the reviewed triggers. Got:
$triggers"
for t in $guarded; do
  grep -Fxq "alter table public.$t enable always trigger ${t}_truncate_guard" <<<"$outline" ||
    fail "${t}_truncate_guard must fire in every session mode"
done
[[ "$(grep -c 'enable always trigger' <<<"$outline")" -eq 4 ]] || fail 'exactly the four truncate guards are enabled always'
grep -Fxq 'revoke truncate on public.observations, public.programme_entries, public.rescue_events, public.lesson_progress from public, anon, authenticated, thsync' <<<"$outline" ||
  fail 'truncate must be revoked on the four record tables from public, anon, authenticated and thsync'
while IFS= read -r stmt; do
  [[ "$stmt" =~ ^create\ trigger\ [a-z_]+_truncate_guard\ before\ truncate\ on\ public\.[a-z_]+\ for\ each\ statement\ execute\ function\ public\.programme_records_truncate_guard\(\)$ ]] && continue
  [[ "$stmt" =~ ^revoke\ truncate\ on\  ]] && continue
  fail "truncate appears outside a guard trigger or the revoke: $stmt"
done < <(grep -E '(^|[^a-z_])truncate([^a-z_]|$)' <<<"$outline" || true)

# delete_my_app_data: the earlier body byte for byte plus only the seven
# declares, the fourteen delete and count lines after the supporters count,
# the seven receipt keys, and the trailing comma on the supporters key.
new_keys='observations programme_entries rescue_events lesson_progress programme_reminders notification_preferences wellbeing_baseline'
programme_keys='observations programme_entries rescue_events lesson_progress programme_reminders'
body_previous=$(sed -n '/^create or replace function public\.delete_my_app_data(p_confirmation text)$/,/^\$\$;$/p' "$app_data_source")
body_new=$(sed -n '/^create or replace function public\.delete_my_app_data(p_confirmation text)$/,/^\$\$;$/p' "$migration")
[[ -n "$body_previous" && -n "$body_new" ]] || fail 'delete_my_app_data bodies not found'
for anchor in '  deleted_supporters integer := 0;' '  get diagnostics deleted_supporters = row_count;' \
  "    'supporters', deleted_supporters"; do
  [[ "$(grep -Fxc "$anchor" <<<"$body_previous")" -eq 1 ]] || fail "the earlier delete_my_app_data body must contain once: $anchor"
done
expected_body=$(awk -v q="'" -v keys="$new_keys" '
  BEGIN { n = split(keys, k, " ") }
  $0 == "    " q "supporters" q ", deleted_supporters" {
    print $0 ","
    for (i = 1; i <= n; i++) printf "    %s%s%s, deleted_%s%s\n", q, k[i], q, k[i], (i < n ? "," : "")
    next
  }
  { print }
  $0 == "  deleted_supporters integer := 0;" {
    for (i = 1; i <= n; i++) printf "  deleted_%s integer := 0;\n", k[i]
  }
  $0 == "  get diagnostics deleted_supporters = row_count;" {
    for (i = 1; i <= n; i++) printf "  delete from public.%s where user_id = caller_id;\n  get diagnostics deleted_%s = row_count;\n", k[i], k[i]
  }
' <<<"$body_previous")
[[ "$body_new" == "$expected_body" ]] ||
  fail "delete_my_app_data must be the $app_data_source body plus only the seven declares, deletes and receipt keys:
$(diff <(echo "$expected_body") <(echo "$body_new") || true)"

# delete_enrolment_now: the earlier body byte for byte (from "returns jsonb")
# plus only the five declares, the ten delete and count lines after the
# caregivers count, the five receipt keys, and the trailing comma on the
# caregivers key.
now_previous=$(sed -n '/^create function public\.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)$/,/^\$\$;$/p' "$delete_now_source" | sed '1d')
now_new=$(sed -n '/^create or replace function public\.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)$/,/^\$\$;$/p' "$migration" | sed '1d')
[[ -n "$now_previous" && -n "$now_new" ]] || fail 'delete_enrolment_now bodies not found'
for anchor in '  deleted_caregivers integer := 0;' '  get diagnostics deleted_caregivers = row_count;' \
  "    'caregivers', deleted_caregivers"; do
  [[ "$(grep -Fxc "$anchor" <<<"$now_previous")" -eq 1 ]] || fail "the earlier delete_enrolment_now body must contain once: $anchor"
done
expected_now=$(awk -v q="'" -v keys="$programme_keys" '
  BEGIN { n = split(keys, k, " ") }
  $0 == "    " q "caregivers" q ", deleted_caregivers" {
    print $0 ","
    for (i = 1; i <= n; i++) printf "    %s%s%s, deleted_%s%s\n", q, k[i], q, k[i], (i < n ? "," : "")
    next
  }
  { print }
  $0 == "  deleted_caregivers integer := 0;" {
    for (i = 1; i <= n; i++) printf "  deleted_%s integer := 0;\n", k[i]
  }
  $0 == "  get diagnostics deleted_caregivers = row_count;" {
    for (i = 1; i <= n; i++) printf "  delete from public.%s where user_id = caller_id and enrolment_id = p_enrolment_id;\n  get diagnostics deleted_%s = row_count;\n", k[i], k[i]
  }
' <<<"$now_previous")
[[ "$now_new" == "$expected_now" ]] ||
  fail "delete_enrolment_now must be the $delete_now_source body plus only the five declares, deletes and receipt keys:
$(diff <(echo "$expected_now") <(echo "$now_new") || true)"

# Every delete in the re-created functions is limited to the caller and, in
# delete_enrolment_now, to that enrolment or its programme.
# Prints each delete statement of the function body on stdin on one line.
delete_statements() {
  sed 's/--.*$//' | awk '
    /^ +delete from / { stmt = ""; on = 1 }
    on { line = $0; sub(/^ +/, "", line); stmt = (stmt == "" ? line : stmt " " line)
         if ($0 ~ /;$/) { print stmt; on = 0 } }
  '
}
now_deletes=$(delete_statements <<<"$now_new")
expected_now_deletes="delete from public.care_share_access where user_id = caller_id and share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id);
delete from public.care_messages where user_id = caller_id and (enrolment_id = p_enrolment_id or share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id));
delete from public.care_shares where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.caregiver_events where user_id = caller_id and caregiver_id in (select id from public.caregivers where enrolment_id = p_enrolment_id);
delete from public.caregivers where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.observations where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.programme_entries where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.rescue_events where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.lesson_progress where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.programme_reminders where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.sync_lapse where user_id = caller_id and programme_code = v_programme_code;
delete from public.sync_answer where user_id = caller_id and programme_code = v_programme_code;
delete from public.sync_area where user_id = caller_id and enrolment_id = p_enrolment_id;
delete from public.programme_consents where enrolment_id = p_enrolment_id and enrolment_id in (select id from public.enrolments where user_id = caller_id);
delete from public.quit_plans where user_id = caller_id;
delete from public.program_data where user_id = caller_id and program_id = (select p.slug from public.programmes as p where p.code = v_programme_code);
delete from public.enrolments where user_id = caller_id and id = p_enrolment_id;"
[[ "$now_deletes" == "$expected_now_deletes" ]] ||
  fail "every delete in delete_enrolment_now must be limited to the caller and to the enrolment or its programme. Got:
$now_deletes"
grep -A1 -Fx "  if v_programme_code = 'bf' then" <<<"$now_new" | grep -Fxq '    delete from public.quit_plans where user_id = caller_id;' ||
  fail 'delete_enrolment_now deletes the quit plan only for BreatheFree'
app_deletes=$(delete_statements <<<"$body_new")
[[ "$(grep -c . <<<"$app_deletes")" -eq 24 ]] || fail 'delete_my_app_data deletes from exactly 24 tables'
while IFS= read -r stmt; do
  [[ "$stmt" =~ ^delete\ from\ public\.[a-z_]+\ where\ (user_id|id)\ =\ caller_id\;$ ]] && continue
  [[ "$stmt" == 'delete from public.programme_consents where enrolment_id in ( select id from public.enrolments where user_id = caller_id );' ]] && continue
  fail "every delete in delete_my_app_data must be limited to the caller (got: $stmt)"
done <<<"$app_deletes"

# Registry: every TH raise in this migration uses a registered code, hint and
# message, and its row names the raising function.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
fn_re='^create (or replace )?function public\.([a-z_]+)\('
raise_re="errcode = '(TH[0-9]{3})', message = '([^']+)', hint = '([a-z_]+)';"
checked=0
codes=''
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
  codes+="$code "
  checked=$((checked + 1))
done < <(sed 's/--.*$//' "$migration" | awk '
  /^create (or replace )?function public\./ { print; next }
  /raise exception using errcode/ { stmt = $0; grab = 1 }
  grab {
    if (stmt != $0) { line = $0; sub(/^ +/, "", line); stmt = stmt " " line }
    if ($0 ~ /;$/) { sub(/^ +/, "", stmt); print stmt; grab = 0 }
  }
')
[[ "$checked" -eq 7 ]] || fail "expected 7 TH raises in $migration, checked $checked"
[[ "$codes" == 'TH026 TH027 TH009 TH010 TH017 TH020 TH012 ' ]] ||
  fail "the migration raises TH026 and TH027, and only the re-created functions' existing codes (got: $codes)"
for row in 'TH026|programme_records_append_only' 'TH027|programme_rows_delete_only'; do
  IFS='|' read -r c name <<<"$row"
  grep -Eq "^\\| \`$c\` \\| \`$name\` \\|" "$contract" || fail "$c $name is not in the registry in $contract"
done
# The payload and attribute checks raise only check_violation (23514).
for name in programme_entries_check_payload observations_check_attributes; do
  body=$(sed -n "/^create function public\\.$name()\$/,/^\\\$\\\$;\$/p" "$migration")
  [[ "$(grep -c 'raise ' <<<"$body")" -eq 2 && "$(grep -c 'raise check_violation using message = ' <<<"$body")" -eq 2 ]] ||
    fail "$name must raise only check_violation (23514)"
done

# Contract.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_programme_records_migration.sh`' "$contract" || fail "$contract must name this check"
grep -Fxq '## Programme records' "$contract" || fail "$contract must have a Programme records section"
deletion_section=$(sed -n '/^## Account-data deletion$/,/^## /p' "$contract" | tr '\n' ' ')
enrolments_section=$(sed -n '/^## Programmes, enrolments and consents$/,/^## /p' "$contract" | tr '\n' ' ')
for k in $new_keys; do
  grep -Fq "\`$k\`" <<<"$deletion_section" || fail "the account-data deletion section must list the receipt key $k"
done
for k in $programme_keys; do
  grep -Fq "\`$k\`" <<<"$enrolments_section" || fail "the enrolments section must list the delete-now receipt key $k"
done

echo 'Programme records static checks passed.'

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
  echo "$out" | grep -q 'TH914B_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH914B_CONTROL_UNKNOWN_KEY_REFUSED' ||
    fail 'control: an observation with an unknown attribute key was not refused'
  echo 'Programme records SQL test and control passed.'
fi
