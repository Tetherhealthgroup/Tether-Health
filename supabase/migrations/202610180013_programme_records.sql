begin;

-- Programme records: observations, programme entries, rescue events, lesson
-- progress and reminder times, plus two account-level settings tables
-- (notification preferences and the wellbeing baseline).
--
-- * Every table holds user_id and cascades from auth.users. The five programme
--   tables also hold programme_code and reference their enrolment through one
--   composite foreign key (enrolment_id, user_id, programme_code), backed by a
--   new unique key on public.enrolments, so each row's member and programme
--   always match its enrolment, whoever writes it. A rescue event may name no
--   enrolment (a shared tool); one that names an enrolment is BreatheFree's.
-- * No table here references the consent, consent document, sync or care
--   tables, and no foreign key sets null or a default.
-- * Row-level security is enabled and forced on all seven tables. Members
--   read their own rows. Every insert policy requires the deletion barrier to
--   be open; programme rows also need a live core consent on the member's own
--   enrolment that is not left. Only the reminder time and the two settings
--   tables can be updated. Every write policy refuses a sync service session.
--   Members cannot delete any of these rows directly.
-- * Programme entry payloads and observation attributes are checked on
--   insert against a fixed key list per kind or metric (23514). Option values
--   are the API's contract, not the database's.
-- * Observations, programme entries, rescue events and lesson progress are
--   append-only (TH026). A trigger refuses removing their rows other than with
--   DELETE, for every role and in every session mode (TH027).
-- * delete_my_app_data also deletes and counts the seven tables; "Delete now"
--   (delete_enrolment_now) also deletes and counts the five programme tables'
--   rows of that enrolment. Their owners, privileges and comments are kept.

-- Enrolment key for the composite foreign keys ---------------------------------------

alter table public.enrolments
add constraint enrolments_id_user_programme_key unique (id, user_id, programme_code);

-- Tables --------------------------------------------------------------------------

create table public.observations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null,
  programme_code text not null,
  submission_id uuid not null,
  metric text not null,
  value numeric(9,3) not null,
  unit_ucum text not null,
  effective_at timestamptz not null,
  attributes jsonb not null default '{}',
  created_at timestamptz not null default now(),
  constraint observations_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade,
  constraint observations_submission_key unique (enrolment_id, submission_id, metric),
  constraint observations_value_check check (value between 0 and 10000),
  constraint observations_effective_at_check check (
    effective_at >= timestamptz '1900-01-01' and effective_at <= created_at + interval '1 day'
  ),
  constraint observations_attributes_check check (
    jsonb_typeof(attributes) = 'object' and octet_length(attributes::text) <= 2048
  ),
  constraint observations_metric_check check (
    (metric in ('bp_systolic', 'bp_diastolic') and unit_ucum = 'mm[Hg]' and programme_code = 'hw') or
    (metric = 'heart_rate' and unit_ucum = '/min' and programme_code = 'hw') or
    (metric in ('chol_total', 'chol_ldl', 'chol_hdl', 'triglycerides')
      and unit_ucum = 'mg/dL' and programme_code = 'hw') or
    (metric = 'glucose' and unit_ucum = 'mg/dL' and programme_code = 'st') or
    (metric = 'a1c' and unit_ucum = '%' and programme_code = 'st') or
    (metric = 'egfr' and unit_ucum = 'mL/min/{1.73_m2}' and programme_code = 're') or
    (metric = 'urine_acr' and unit_ucum = 'mg/g' and programme_code = 're') or
    (metric = 'alt' and unit_ucum = 'U/L' and programme_code = 're') or
    (metric = 'peak_flow' and unit_ucum = 'L/min' and programme_code = 'ca')
  )
);

create index observations_user_idx on public.observations (user_id);

comment on table public.observations is
  'Measurements a member records in a programme: an internal metric with its fixed UCUM unit. Append-only.';

create table public.programme_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null,
  programme_code text not null,
  submission_id uuid not null,
  kind text not null,
  occurred_at timestamptz not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  constraint programme_entries_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade,
  constraint programme_entries_submission_key unique (enrolment_id, submission_id),
  constraint programme_entries_kind_check check (
    kind in ('checkin', 'ca.zone_check', 'ca.symptom', 'ea.mood', 'ea.check_back', 'sd.session',
             'sd.fall', 'sf.pause', 'ck.done', 'be.diary', 'be.survivorship')
  ),
  constraint programme_entries_kind_programme_check check (
    kind = 'checkin' or split_part(kind, '.', 1) = programme_code
  ),
  constraint programme_entries_occurred_at_check check (
    occurred_at >= timestamptz '2000-01-01' and occurred_at <= created_at + interval '5 minutes'
  ),
  constraint programme_entries_payload_check check (
    jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 4096
  )
);

create index programme_entries_user_idx on public.programme_entries (user_id);

comment on table public.programme_entries is
  'Check-ins and programme events a member logs, one row per enrolment. The payload keys are fixed per kind. Append-only.';

create table public.rescue_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid null,
  programme_code text null,
  submission_id uuid not null,
  tool text not null,
  opened_at timestamptz not null,
  intensity_before smallint null,
  intensity_after smallint null,
  helped text null,
  escalated boolean not null default false,
  created_at timestamptz not null default now(),
  constraint rescue_events_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade,
  constraint rescue_events_submission_key unique (user_id, submission_id),
  constraint rescue_events_enrolment_check check ((enrolment_id is null) = (programme_code is null)),
  constraint rescue_events_programme_check check (programme_code is null or programme_code = 'bf'),
  constraint rescue_events_tool_check check (tool ~ '^[a-z0-9_]{1,40}$'),
  constraint rescue_events_opened_at_check check (
    opened_at >= timestamptz '2000-01-01' and opened_at <= created_at + interval '5 minutes'
  ),
  constraint rescue_events_intensity_before_check check (intensity_before between 0 and 10),
  constraint rescue_events_intensity_after_check check (intensity_after between 0 and 10),
  constraint rescue_events_helped_check check (helped in ('yes', 'a_little', 'no'))
);

create index rescue_events_enrolment_idx on public.rescue_events (enrolment_id);

comment on table public.rescue_events is
  'Rescue tools a member opened. A rescue tied to no enrolment is account-level (a shared tool). Append-only.';

create table public.lesson_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null,
  programme_code text not null,
  lesson_id text not null,
  completed_at timestamptz not null default now(),
  constraint lesson_progress_pkey primary key (enrolment_id, lesson_id),
  constraint lesson_progress_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade,
  constraint lesson_progress_lesson_id_check check (lesson_id ~ '^[a-z0-9][a-z0-9_.-]{0,79}$')
);

create index lesson_progress_user_idx on public.lesson_progress (user_id);

comment on table public.lesson_progress is
  'Lessons a member completed in a programme. Append-only.';

create table public.programme_reminders (
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null,
  programme_code text not null,
  remind_at time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint programme_reminders_pkey primary key (enrolment_id),
  constraint programme_reminders_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade
);

create index programme_reminders_user_idx on public.programme_reminders (user_id);

create trigger programme_reminders_set_updated_at
before update on public.programme_reminders
for each row execute function public.set_updated_at();

comment on table public.programme_reminders is
  'A programme''s daily reminder time. Storing it sends nothing: whether a reminder fires stays governed by the programme''s reminders consent.';

create table public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reminders_enabled boolean not null default false,
  sensitive_details boolean not null default false,
  quiet_hours_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at();

comment on table public.notification_preferences is
  'A member''s account-level notification switches. Quiet hours are fixed, so no times are stored.';

create table public.wellbeing_baseline (
  user_id uuid primary key references auth.users(id) on delete cascade,
  age_range text null,
  sleep_band text null,
  stress_band text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wellbeing_baseline_age_range_check check (age_range ~ '^[0-9]{2}_([0-9]{2}|plus)$'),
  constraint wellbeing_baseline_sleep_band_check check (sleep_band in ('lt5', '5_6', '7_8', '9plus')),
  constraint wellbeing_baseline_stress_band_check check (stress_band in ('low', 'some', 'high'))
);

create trigger wellbeing_baseline_set_updated_at
before update on public.wellbeing_baseline
for each row execute function public.set_updated_at();

comment on table public.wellbeing_baseline is
  'A member''s onboarding baseline (age range, sleep and stress bands). Account-level, never shared.';

-- Payload and attribute checks -------------------------------------------------------

-- Each kind has a fixed set of keys, some required, each of one type: code
-- (^[a-z0-9_]{1,40}$), codes (0 to 12 distinct codes), score (an integer 0 to
-- 10), text (a trimmed string of 1 to 500 characters) or date (a valid
-- YYYY-MM-DD). An unknown kind is left to the kind check constraint.
create function public.programme_entries_check_payload()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  spec jsonb;
  required text[] := '{}';
  entry record;
  kind_type text;
  valid boolean := true;
  parsed date;
begin
  if jsonb_typeof(new.payload) is distinct from 'object' then
    raise check_violation using message = 'Programme entry payload is not valid for its kind';
  end if;

  case new.kind
    when 'checkin' then
      spec := '{"feel": "code", "stress": "code", "answer": "code"}';
    when 'ca.zone_check' then
      spec := '{"zone": "code", "symptoms": "codes"}';
      required := array['zone'];
    when 'ca.symptom' then
      spec := '{"symptoms": "codes", "severity": "code", "triggers": "codes", "note": "text"}';
      required := array['symptoms'];
    when 'ea.mood' then
      spec := '{"mood": "code", "topics": "codes"}';
      required := array['mood'];
    when 'ea.check_back' then
      spec := '{"change": "code", "reached_out": "code"}';
      required := array['change'];
    when 'sd.session' then
      spec := '{"settings": "codes"}';
    when 'sd.fall' then
      spec := '{}';
    when 'sf.pause' then
      spec := '{"reason": "code"}';
      required := array['reason'];
    when 'ck.done' then
      spec := '{"item": "code", "done_on": "date", "place": "text"}';
      required := array['item', 'done_on'];
    when 'be.diary' then
      spec := '{"fatigue": "score", "symptoms": "codes"}';
      required := array['fatigue'];
    when 'be.survivorship' then
      spec := '{"feeling": "code"}';
      required := array['feeling'];
    else
      return new;
  end case;

  if new.kind = 'checkin' and not (new.payload ?| array['feel', 'stress', 'answer']) then
    valid := false;
  end if;
  if not (new.payload ?& required) then
    valid := false;
  end if;

  for entry in select e.key, e.value from jsonb_each(new.payload) as e loop
    exit when not valid;
    kind_type := spec ->> entry.key;
    if kind_type is null then
      valid := false;
    elsif kind_type = 'code' then
      valid := jsonb_typeof(entry.value) = 'string'
        and (entry.value #>> '{}') ~ '^[a-z0-9_]{1,40}$';
    elsif kind_type = 'codes' then
      valid := jsonb_typeof(entry.value) = 'array'
        and jsonb_array_length(entry.value) <= 12
        and (select coalesce(bool_and(jsonb_typeof(c.value) = 'string'
                                      and (c.value #>> '{}') ~ '^[a-z0-9_]{1,40}$'), true)
                    and count(*) = count(distinct c.value)
             from jsonb_array_elements(entry.value) as c);
    elsif kind_type = 'score' then
      valid := jsonb_typeof(entry.value) = 'number'
        and (entry.value #>> '{}') ~ '^([0-9]|10)$';
    elsif kind_type = 'text' then
      valid := jsonb_typeof(entry.value) = 'string'
        and (entry.value #>> '{}') = btrim(entry.value #>> '{}')
        and char_length(entry.value #>> '{}') between 1 and 500;
    elsif kind_type = 'date' then
      valid := jsonb_typeof(entry.value) = 'string'
        and (entry.value #>> '{}') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
      if valid then
        begin
          parsed := (entry.value #>> '{}')::date;
          valid := to_char(parsed, 'YYYY-MM-DD') = (entry.value #>> '{}');
        exception when others then
          valid := false;
        end;
      end if;
    else
      valid := false;
    end if;
  end loop;

  if not coalesce(valid, false) then
    raise check_violation using message = 'Programme entry payload is not valid for its kind';
  end if;
  return new;
end;
$$;

revoke all on function public.programme_entries_check_payload()
from public, anon, authenticated, service_role;

create trigger programme_entries_check_payload
before insert on public.programme_entries
for each row execute function public.programme_entries_check_payload();

-- Glucose may carry timing (code), feelings (codes) and a note (text); every
-- other metric carries no attributes. An unknown metric is left to the metric
-- check constraint.
create function public.observations_check_attributes()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  entry record;
  valid boolean := true;
begin
  if jsonb_typeof(new.attributes) is distinct from 'object' then
    raise check_violation using message = 'Observation attributes are not valid for this metric';
  end if;

  if new.metric = 'glucose' then
    for entry in select e.key, e.value from jsonb_each(new.attributes) as e loop
      exit when not valid;
      if entry.key = 'timing' then
        valid := jsonb_typeof(entry.value) = 'string'
          and (entry.value #>> '{}') ~ '^[a-z0-9_]{1,40}$';
      elsif entry.key = 'feelings' then
        valid := jsonb_typeof(entry.value) = 'array'
          and jsonb_array_length(entry.value) <= 12
          and (select coalesce(bool_and(jsonb_typeof(c.value) = 'string'
                                        and (c.value #>> '{}') ~ '^[a-z0-9_]{1,40}$'), true)
                      and count(*) = count(distinct c.value)
               from jsonb_array_elements(entry.value) as c);
      elsif entry.key = 'note' then
        valid := jsonb_typeof(entry.value) = 'string'
          and (entry.value #>> '{}') = btrim(entry.value #>> '{}')
          and char_length(entry.value #>> '{}') between 1 and 500;
      else
        valid := false;
      end if;
    end loop;
  elsif new.metric in ('bp_systolic', 'bp_diastolic', 'heart_rate', 'chol_total', 'chol_ldl',
                       'chol_hdl', 'triglycerides', 'a1c', 'egfr', 'urine_acr', 'alt', 'peak_flow') then
    valid := new.attributes = '{}'::jsonb;
  end if;

  if not coalesce(valid, false) then
    raise check_violation using message = 'Observation attributes are not valid for this metric';
  end if;
  return new;
end;
$$;

revoke all on function public.observations_check_attributes()
from public, anon, authenticated, service_role;

create trigger observations_check_attributes
before insert on public.observations
for each row execute function public.observations_check_attributes();

-- Append-only ----------------------------------------------------------------------

create function public.programme_records_append_only()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH026',
    message = 'Programme records are append-only',
    hint = 'programme_records_append_only';
end;
$$;

revoke all on function public.programme_records_append_only()
from public, anon, authenticated, service_role;

create trigger observations_append_only
before update on public.observations
for each row execute function public.programme_records_append_only();

create trigger programme_entries_append_only
before update on public.programme_entries
for each row execute function public.programme_records_append_only();

create trigger rescue_events_append_only
before update on public.rescue_events
for each row execute function public.programme_records_append_only();

create trigger lesson_progress_append_only
before update on public.lesson_progress
for each row execute function public.programme_records_append_only();

-- Row-level security, policies and grants --------------------------------------------

alter table public.observations enable row level security;
alter table public.observations force row level security;
alter table public.programme_entries enable row level security;
alter table public.programme_entries force row level security;
alter table public.rescue_events enable row level security;
alter table public.rescue_events force row level security;
alter table public.lesson_progress enable row level security;
alter table public.lesson_progress force row level security;
alter table public.programme_reminders enable row level security;
alter table public.programme_reminders force row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_preferences force row level security;
alter table public.wellbeing_baseline enable row level security;
alter table public.wellbeing_baseline force row level security;

revoke all on table public.observations from public, anon, authenticated, service_role;
revoke all on table public.programme_entries from public, anon, authenticated, service_role;
revoke all on table public.rescue_events from public, anon, authenticated, service_role;
revoke all on table public.lesson_progress from public, anon, authenticated, service_role;
revoke all on table public.programme_reminders from public, anon, authenticated, service_role;
revoke all on table public.notification_preferences from public, anon, authenticated, service_role;
revoke all on table public.wellbeing_baseline from public, anon, authenticated, service_role;

-- Observations.
create policy "observations_select_own"
on public.observations for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "observations_insert_own"
on public.observations for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.has_consent(enrolment_id, 'core') and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.observations to authenticated;
grant insert (user_id, enrolment_id, programme_code, submission_id, metric, value, unit_ucum, effective_at, attributes)
on table public.observations to authenticated;

-- Programme entries.
create policy "programme_entries_select_own"
on public.programme_entries for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "programme_entries_insert_own"
on public.programme_entries for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.has_consent(enrolment_id, 'core') and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.programme_entries to authenticated;
grant insert (user_id, enrolment_id, programme_code, submission_id, kind, occurred_at, payload)
on table public.programme_entries to authenticated;

-- Rescue events: a shared rescue names no enrolment and needs no consent.
create policy "rescue_events_select_own"
on public.rescue_events for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "rescue_events_insert_own"
on public.rescue_events for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  (enrolment_id is null or public.has_consent(enrolment_id, 'core')) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.rescue_events to authenticated;
grant insert (user_id, enrolment_id, programme_code, submission_id, tool, opened_at, intensity_before, intensity_after, helped, escalated)
on table public.rescue_events to authenticated;

-- Lesson progress.
create policy "lesson_progress_select_own"
on public.lesson_progress for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "lesson_progress_insert_own"
on public.lesson_progress for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.has_consent(enrolment_id, 'core') and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.lesson_progress to authenticated;
grant insert (user_id, enrolment_id, programme_code, lesson_id)
on table public.lesson_progress to authenticated;

-- Programme reminders: members change only the time.
create policy "programme_reminders_select_own"
on public.programme_reminders for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "programme_reminders_insert_own"
on public.programme_reminders for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.has_consent(enrolment_id, 'core') and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "programme_reminders_update_own"
on public.programme_reminders for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.programme_reminders to authenticated;
grant insert (user_id, enrolment_id, programme_code, remind_at)
on table public.programme_reminders to authenticated;
grant update (remind_at) on table public.programme_reminders to authenticated;

-- Notification preferences (account-level).
create policy "notification_preferences_select_own"
on public.notification_preferences for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "notification_preferences_insert_own"
on public.notification_preferences for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "notification_preferences_update_own"
on public.notification_preferences for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.notification_preferences to authenticated;
grant insert (user_id, reminders_enabled, sensitive_details, quiet_hours_enabled)
on table public.notification_preferences to authenticated;
grant update (reminders_enabled, sensitive_details, quiet_hours_enabled)
on table public.notification_preferences to authenticated;

-- Wellbeing baseline (account-level, never shared).
create policy "wellbeing_baseline_select_own"
on public.wellbeing_baseline for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "wellbeing_baseline_insert_own"
on public.wellbeing_baseline for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "wellbeing_baseline_update_own"
on public.wellbeing_baseline for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.wellbeing_baseline to authenticated;
grant insert (user_id, age_range, sleep_band, stress_band)
on table public.wellbeing_baseline to authenticated;
grant update (age_range, sleep_band, stress_band)
on table public.wellbeing_baseline to authenticated;

-- Truncate guards ------------------------------------------------------------------

create function public.programme_records_truncate_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH027',
    message = 'Programme records are removed only with their programme or account',
    hint = 'programme_rows_delete_only';
end;
$$;

revoke all on function public.programme_records_truncate_guard()
from public, anon, authenticated, service_role;

create trigger observations_truncate_guard
before truncate on public.observations
for each statement execute function public.programme_records_truncate_guard();

create trigger programme_entries_truncate_guard
before truncate on public.programme_entries
for each statement execute function public.programme_records_truncate_guard();

create trigger rescue_events_truncate_guard
before truncate on public.rescue_events
for each statement execute function public.programme_records_truncate_guard();

create trigger lesson_progress_truncate_guard
before truncate on public.lesson_progress
for each statement execute function public.programme_records_truncate_guard();

alter table public.observations
enable always trigger observations_truncate_guard;
alter table public.programme_entries
enable always trigger programme_entries_truncate_guard;
alter table public.rescue_events
enable always trigger rescue_events_truncate_guard;
alter table public.lesson_progress
enable always trigger lesson_progress_truncate_guard;

revoke truncate on public.observations, public.programme_entries, public.rescue_events,
  public.lesson_progress
from public, anon, authenticated, thsync;

-- Account deletion ----------------------------------------------------------------
-- delete_my_app_data also deletes and counts the seven tables, before the
-- consents and enrolments. Everything else is unchanged; its owner,
-- privileges and comment are kept.
create or replace function public.delete_my_app_data(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  deleted_profiles integer := 0;
  deleted_quit_plans integer := 0;
  deleted_program_data integer := 0;
  deleted_enrolments integer := 0;
  deleted_programme_consents integer := 0;
  deleted_account_consents integer := 0;
  deleted_sync_answers integer := 0;
  deleted_sync_lapses integer := 0;
  deleted_sync_areas integer := 0;
  deleted_sync_accounts integer := 0;
  deleted_care_share_access integer := 0;
  deleted_care_messages integer := 0;
  deleted_care_shares integer := 0;
  deleted_caregiver_events integer := 0;
  deleted_caregivers integer := 0;
  deleted_care_connections integer := 0;
  deleted_supporters integer := 0;
  deleted_observations integer := 0;
  deleted_programme_entries integer := 0;
  deleted_rescue_events integer := 0;
  deleted_lesson_progress integer := 0;
  deleted_programme_reminders integer := 0;
  deleted_notification_preferences integer := 0;
  deleted_wellbeing_baseline integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH009',
      message = 'Account deletion goes through the API',
      hint = 'deletion_via_api_only';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;
  if exists (
    select 1
    from public.profiles
    where id = caller_id and account_deletion_started_at is null
  ) then
    raise check_violation using message = 'Account deletion was not started';
  end if;

  delete from public.sync_lapse where user_id = caller_id;
  get diagnostics deleted_sync_lapses = row_count;
  delete from public.sync_answer where user_id = caller_id;
  get diagnostics deleted_sync_answers = row_count;
  delete from public.sync_area where user_id = caller_id;
  get diagnostics deleted_sync_areas = row_count;
  delete from public.sync_account where user_id = caller_id;
  get diagnostics deleted_sync_accounts = row_count;
  delete from public.care_share_access where user_id = caller_id;
  get diagnostics deleted_care_share_access = row_count;
  delete from public.care_messages where user_id = caller_id;
  get diagnostics deleted_care_messages = row_count;
  delete from public.care_shares where user_id = caller_id;
  get diagnostics deleted_care_shares = row_count;
  delete from public.caregiver_events where user_id = caller_id;
  get diagnostics deleted_caregiver_events = row_count;
  delete from public.caregivers where user_id = caller_id;
  get diagnostics deleted_caregivers = row_count;
  delete from public.care_connections where user_id = caller_id;
  get diagnostics deleted_care_connections = row_count;
  delete from public.supporters where user_id = caller_id;
  get diagnostics deleted_supporters = row_count;
  delete from public.observations where user_id = caller_id;
  get diagnostics deleted_observations = row_count;
  delete from public.programme_entries where user_id = caller_id;
  get diagnostics deleted_programme_entries = row_count;
  delete from public.rescue_events where user_id = caller_id;
  get diagnostics deleted_rescue_events = row_count;
  delete from public.lesson_progress where user_id = caller_id;
  get diagnostics deleted_lesson_progress = row_count;
  delete from public.programme_reminders where user_id = caller_id;
  get diagnostics deleted_programme_reminders = row_count;
  delete from public.notification_preferences where user_id = caller_id;
  get diagnostics deleted_notification_preferences = row_count;
  delete from public.wellbeing_baseline where user_id = caller_id;
  get diagnostics deleted_wellbeing_baseline = row_count;
  delete from public.programme_consents
  where enrolment_id in (
    select id from public.enrolments where user_id = caller_id
  );
  get diagnostics deleted_programme_consents = row_count;
  delete from public.enrolments where user_id = caller_id;
  get diagnostics deleted_enrolments = row_count;
  delete from public.account_consents where user_id = caller_id;
  get diagnostics deleted_account_consents = row_count;
  delete from public.program_data where user_id = caller_id;
  get diagnostics deleted_program_data = row_count;
  delete from public.quit_plans where user_id = caller_id;
  get diagnostics deleted_quit_plans = row_count;
  delete from public.profiles where id = caller_id;
  get diagnostics deleted_profiles = row_count;

  return jsonb_build_object(
    'profiles', deleted_profiles,
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data,
    'enrolments', deleted_enrolments,
    'programme_consents', deleted_programme_consents,
    'account_consents', deleted_account_consents,
    'sync_answers', deleted_sync_answers,
    'sync_lapses', deleted_sync_lapses,
    'sync_areas', deleted_sync_areas,
    'sync_accounts', deleted_sync_accounts,
    'care_share_access', deleted_care_share_access,
    'care_messages', deleted_care_messages,
    'care_shares', deleted_care_shares,
    'caregiver_events', deleted_caregiver_events,
    'caregivers', deleted_caregivers,
    'care_connections', deleted_care_connections,
    'supporters', deleted_supporters,
    'observations', deleted_observations,
    'programme_entries', deleted_programme_entries,
    'rescue_events', deleted_rescue_events,
    'lesson_progress', deleted_lesson_progress,
    'programme_reminders', deleted_programme_reminders,
    'notification_preferences', deleted_notification_preferences,
    'wellbeing_baseline', deleted_wellbeing_baseline
  );
end;
$$;

-- Delete now ------------------------------------------------------------------------
-- delete_enrolment_now also deletes and counts the enrolment's observations,
-- programme entries, rescue events, lesson progress and reminder time.
-- Everything else is unchanged; its owner and privileges are kept.
create or replace function public.delete_enrolment_now(p_enrolment_id uuid, p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  newest_sign_in numeric;
  sign_in_age numeric;
  v_programme_code text;
  deleted_quit_plans integer := 0;
  deleted_program_data integer := 0;
  deleted_enrolments integer := 0;
  deleted_programme_consents integer := 0;
  deleted_sync_answers integer := 0;
  deleted_sync_lapses integer := 0;
  deleted_sync_areas integer := 0;
  deleted_care_share_access integer := 0;
  deleted_care_messages integer := 0;
  deleted_care_shares integer := 0;
  deleted_caregiver_events integer := 0;
  deleted_caregivers integer := 0;
  deleted_observations integer := 0;
  deleted_programme_entries integer := 0;
  deleted_rescue_events integer := 0;
  deleted_lesson_progress integer := 0;
  deleted_programme_reminders integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;

  -- Recent sign-in: the newest amr entry with a string method and a numeric
  -- timestamp (seconds since the epoch). Anything else counts as missing.
  select max((m.entry ->> 'timestamp')::numeric)
  into newest_sign_in
  from jsonb_array_elements(
    case when jsonb_typeof(auth.jwt() -> 'amr') = 'array'
         then auth.jwt() -> 'amr' else '[]'::jsonb end
  ) as m(entry)
  where jsonb_typeof(m.entry) = 'object'
    and jsonb_typeof(m.entry -> 'method') = 'string'
    and jsonb_typeof(m.entry -> 'timestamp') = 'number';
  sign_in_age := extract(epoch from now()) - newest_sign_in;
  if sign_in_age is null or sign_in_age > 600 or sign_in_age < -60 then
    raise exception using errcode = 'TH017',
      message = 'Recent authentication is required',
      hint = 'recent_authentication_required';
  end if;

  -- The checks and deletes below run as the function owner and must see
  -- every row: the owner has to bypass row-level security.
  if not exists (
    select 1 from pg_catalog.pg_roles as r
    where r.rolname = current_user and (r.rolsuper or r.rolbypassrls)
  ) then
    raise exception using errcode = 'TH020',
      message = 'Account deletion requires a function owner that bypasses row-level security',
      hint = 'rls_bypass_required';
  end if;

  select e.programme_code
  into v_programme_code
  from public.enrolments as e
  where e.id = p_enrolment_id
    and e.user_id = caller_id
  for update;
  if not found then
    raise exception using errcode = 'TH012',
      message = 'Enrolment not found',
      hint = 'enrolment_not_found';
  end if;

  delete from public.care_share_access
  where user_id = caller_id
    and share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id);
  get diagnostics deleted_care_share_access = row_count;
  delete from public.care_messages
  where user_id = caller_id
    and (enrolment_id = p_enrolment_id
         or share_id in (select id from public.care_shares where enrolment_id = p_enrolment_id));
  get diagnostics deleted_care_messages = row_count;
  delete from public.care_shares
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_care_shares = row_count;
  delete from public.caregiver_events
  where user_id = caller_id
    and caregiver_id in (select id from public.caregivers where enrolment_id = p_enrolment_id);
  get diagnostics deleted_caregiver_events = row_count;
  delete from public.caregivers
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_caregivers = row_count;
  delete from public.observations where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_observations = row_count;
  delete from public.programme_entries where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_programme_entries = row_count;
  delete from public.rescue_events where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_rescue_events = row_count;
  delete from public.lesson_progress where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_lesson_progress = row_count;
  delete from public.programme_reminders where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_programme_reminders = row_count;
  delete from public.sync_lapse
  where user_id = caller_id and programme_code = v_programme_code;
  get diagnostics deleted_sync_lapses = row_count;
  delete from public.sync_answer
  where user_id = caller_id and programme_code = v_programme_code;
  get diagnostics deleted_sync_answers = row_count;
  delete from public.sync_area
  where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_sync_areas = row_count;
  delete from public.programme_consents
  where enrolment_id = p_enrolment_id
    and enrolment_id in (select id from public.enrolments where user_id = caller_id);
  get diagnostics deleted_programme_consents = row_count;
  if v_programme_code = 'bf' then
    delete from public.quit_plans where user_id = caller_id;
    get diagnostics deleted_quit_plans = row_count;
  end if;
  delete from public.program_data
  where user_id = caller_id
    and program_id = (select p.slug from public.programmes as p where p.code = v_programme_code);
  get diagnostics deleted_program_data = row_count;
  delete from public.enrolments
  where user_id = caller_id and id = p_enrolment_id;
  get diagnostics deleted_enrolments = row_count;

  return jsonb_build_object(
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data,
    'enrolments', deleted_enrolments,
    'programme_consents', deleted_programme_consents,
    'sync_answers', deleted_sync_answers,
    'sync_lapses', deleted_sync_lapses,
    'sync_areas', deleted_sync_areas,
    'care_share_access', deleted_care_share_access,
    'care_messages', deleted_care_messages,
    'care_shares', deleted_care_shares,
    'caregiver_events', deleted_caregiver_events,
    'caregivers', deleted_caregivers,
    'observations', deleted_observations,
    'programme_entries', deleted_programme_entries,
    'rescue_events', deleted_rescue_events,
    'lesson_progress', deleted_lesson_progress,
    'programme_reminders', deleted_programme_reminders
  );
end;
$$;

commit;
