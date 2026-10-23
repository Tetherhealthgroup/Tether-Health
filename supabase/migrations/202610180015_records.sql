begin;

-- Health records: sources, imports, imported items and their routing to
-- programmes.
--
-- * public.record_categories lists the record categories a programme may
--   receive; it is seeded with exactly the distinct values of
--   public.programmes.receives_resources. public.record_category_codes maps a
--   code (LOINC or CVX) to a category; it starts empty and is filled by a
--   later reviewed seed. Both are reference data: members read them and
--   nobody writes them through the API.
-- * public.record_sources is one member's connection to a records source
--   (Epic, Oracle Health, Blue Button, any SMART on FHIR server, the phone's
--   health store, or manual entry). FHIR sources carry their https base URL;
--   the others carry none. A member has at most one manual, one Apple Health
--   and one Health Connect source. Sources are never deleted by members:
--   disconnecting sets the status.
-- * public.record_imports is one sync run of a source; public.record_items
--   holds each imported or manually entered value, waiting for the member's
--   review (pending_review or conflict) until accepted or rejected. Items are
--   unique per member by dedupe_key (code, date and value).
-- * public.record_routes gives an accepted item to one programme. A route
--   needs the enrolment's live records_import consent, an accepted item of
--   the same member, and a category the programme receives
--   (programmes.receives_resources), so programmes with an empty list never
--   receive records.
-- * Every member table holds user_id and cascades from auth.users; children
--   cascade from their source and item through composite foreign keys that
--   include user_id, and routes cascade from their enrolment. No table here
--   references the consent, sync or care tables, and no foreign key sets null
--   or a default.
-- * Row-level security is enabled and forced on all six tables. Every write
--   policy refuses a sync service session; every insert policy requires the
--   deletion barrier to be open. Members cannot delete rows directly.
-- * A trigger refuses TRUNCATE on the four member tables for every role
--   (TH028).
-- * public.delete_record_source_items(p_source_id, p_confirmation) deletes the
--   routes, items and imports of one of the caller's sources and returns the
--   three counts. It refuses, in this order: no caller (42501); a sync service
--   session (TH010); a confirmation other than 'DELETE' (23514); a function
--   owner that neither is a superuser nor bypasses row-level security
--   (TH020); a source that does not exist or is not the caller's (TH029). The
--   source row stays.
-- * delete_my_app_data also deletes and counts the four member tables;
--   delete_enrolment_now also deletes and counts the enrolment's routes.
--   Their owners, privileges and comments are kept.

-- Reference tables ---------------------------------------------------------------

create table public.record_categories (
  category text primary key,
  created_at timestamptz not null default now(),
  constraint record_categories_category_check check (category ~ '^[a-z][a-z0-9_]{1,31}$')
);

comment on table public.record_categories is
  'Record categories a programme may receive (reference data, no user data).';

insert into public.record_categories (category)
select distinct r.category
from public.programmes as p
cross join lateral unnest(p.receives_resources) as r(category)
order by r.category;

create table public.record_category_codes (
  code_system text not null,
  code text not null,
  category text not null references public.record_categories (category) on delete restrict,
  unit_ucum text null,
  mapping_version smallint not null,
  constraint record_category_codes_pkey primary key (code_system, code),
  constraint record_category_codes_code_system_check check (
    code_system in ('http://loinc.org', 'http://hl7.org/fhir/sid/cvx')
  ),
  constraint record_category_codes_code_check check (code ~ '^[0-9A-Za-z.-]{1,20}$'),
  constraint record_category_codes_unit_check check (
    unit_ucum is null or char_length(unit_ucum) between 1 and 32
  ),
  constraint record_category_codes_mapping_version_check check (mapping_version > 0)
);

comment on table public.record_category_codes is
  'Which code (LOINC or CVX) belongs to which record category (reference data, no user data). Empty until a reviewed seed fills it.';

-- Member tables ------------------------------------------------------------------

create table public.record_sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null,
  fhir_base_url text null,
  display_name text not null,
  status text not null,
  last_synced_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint record_sources_id_user_key unique (id, user_id),
  constraint record_sources_kind_check check (
    kind in ('epic', 'oracle', 'bluebutton', 'smart', 'apple_health', 'health_connect', 'manual')
  ),
  constraint record_sources_fhir_base_url_check check (
    fhir_base_url is null or (
      fhir_base_url ~ '^https://' and char_length(fhir_base_url) <= 2048
    )
  ),
  constraint record_sources_fhir_base_url_kind_check check (
    (kind in ('epic', 'oracle', 'bluebutton', 'smart')) = (fhir_base_url is not null)
  ),
  constraint record_sources_display_name_check check (
    display_name = btrim(display_name) and char_length(display_name) between 1 and 80
  ),
  constraint record_sources_status_check check (
    status in ('connected', 'needs_reauth', 'disconnected')
  )
);

create unique index record_sources_single_kind_key
on public.record_sources (user_id, kind)
where kind in ('manual', 'apple_health', 'health_connect');

comment on table public.record_sources is
  'A member''s records source. fhir_base_url is member-supplied and untrusted: the API checks it before every outbound call. Never deleted by members; disconnecting sets the status.';

create trigger record_sources_set_updated_at
before update on public.record_sources
for each row execute function public.set_updated_at();

create table public.record_imports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id uuid not null,
  status text not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz null,
  counts jsonb not null default '{}',
  constraint record_imports_id_user_key unique (id, user_id),
  constraint record_imports_source_fkey foreign key (source_id, user_id)
    references public.record_sources (id, user_id) on delete cascade,
  constraint record_imports_status_check check (
    status in ('running', 'succeeded', 'failed')
  ),
  constraint record_imports_counts_check check (
    jsonb_typeof(counts) = 'object' and octet_length(counts::text) <= 1024
  )
);

create index record_imports_source_idx on public.record_imports (source_id);

comment on table public.record_imports is
  'One sync run of a records source, with its counts (numbers only, no values).';

create table public.record_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_id uuid not null,
  import_id uuid null,
  resource_type text not null,
  fhir_id text null,
  category text null references public.record_categories (category) on delete restrict,
  code_system text not null,
  code text not null,
  display text not null,
  value_num numeric(12,4) null,
  value_text text null,
  unit_ucum text null,
  effective_at timestamptz null,
  status text not null default 'pending_review',
  dedupe_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint record_items_id_user_key unique (id, user_id),
  constraint record_items_dedupe_key unique (user_id, dedupe_key),
  constraint record_items_source_fkey foreign key (source_id, user_id)
    references public.record_sources (id, user_id) on delete cascade,
  constraint record_items_import_fkey foreign key (import_id, user_id)
    references public.record_imports (id, user_id) on delete cascade,
  constraint record_items_resource_type_check check (
    resource_type in ('Observation', 'Condition', 'MedicationRequest', 'Immunization')
  ),
  constraint record_items_fhir_id_check check (
    fhir_id is null or fhir_id ~ '^[A-Za-z0-9.-]{1,64}$'
  ),
  constraint record_items_code_system_check check (char_length(code_system) between 1 and 200),
  constraint record_items_code_check check (char_length(code) between 1 and 64),
  constraint record_items_display_check check (
    display = btrim(display) and char_length(display) between 1 and 200
  ),
  constraint record_items_value_text_check check (
    value_text is null or char_length(value_text) between 1 and 200
  ),
  constraint record_items_unit_check check (
    unit_ucum is null or char_length(unit_ucum) between 1 and 32
  ),
  constraint record_items_effective_at_check check (
    effective_at is null or (
      effective_at >= timestamptz '1900-01-01' and effective_at <= created_at + interval '1 day'
    )
  ),
  constraint record_items_status_check check (
    status in ('pending_review', 'accepted', 'rejected', 'conflict')
  ),
  constraint record_items_dedupe_key_check check (char_length(dedupe_key) between 1 and 300)
);

create index record_items_source_idx on public.record_items (source_id);
create index record_items_import_idx on public.record_items (import_id);

comment on table public.record_items is
  'One imported or manually entered health value. Readers use only accepted items; status changes are the API''s.';

create trigger record_items_set_updated_at
before update on public.record_items
for each row execute function public.set_updated_at();

create table public.record_routes (
  record_item_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null,
  programme_code text not null,
  created_at timestamptz not null default now(),
  constraint record_routes_pkey primary key (record_item_id, enrolment_id),
  constraint record_routes_item_fkey foreign key (record_item_id, user_id)
    references public.record_items (id, user_id) on delete cascade,
  constraint record_routes_enrolment_fkey foreign key (enrolment_id, user_id, programme_code)
    references public.enrolments (id, user_id, programme_code) on delete cascade
);

create index record_routes_enrolment_idx on public.record_routes (enrolment_id);

comment on table public.record_routes is
  'An accepted record item given to one programme, under that enrolment''s live records_import consent and only for a category the programme receives.';

-- Row-level security, policies and grants --------------------------------------------

alter table public.record_categories enable row level security;
alter table public.record_categories force row level security;
alter table public.record_category_codes enable row level security;
alter table public.record_category_codes force row level security;
alter table public.record_sources enable row level security;
alter table public.record_sources force row level security;
alter table public.record_imports enable row level security;
alter table public.record_imports force row level security;
alter table public.record_items enable row level security;
alter table public.record_items force row level security;
alter table public.record_routes enable row level security;
alter table public.record_routes force row level security;

revoke all on table public.record_categories from public, anon, authenticated, service_role;
revoke all on table public.record_category_codes from public, anon, authenticated, service_role;
revoke all on table public.record_sources from public, anon, authenticated, service_role;
revoke all on table public.record_imports from public, anon, authenticated, service_role;
revoke all on table public.record_items from public, anon, authenticated, service_role;
revoke all on table public.record_routes from public, anon, authenticated, service_role;

-- Reference data: read only.
create policy "record_categories_select_authenticated"
on public.record_categories for select
to authenticated
using (true);

grant select on table public.record_categories to authenticated;

create policy "record_category_codes_select_authenticated"
on public.record_category_codes for select
to authenticated
using (true);

grant select on table public.record_category_codes to authenticated;

-- Sources.
create policy "record_sources_select_own"
on public.record_sources for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "record_sources_insert_own"
on public.record_sources for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "record_sources_update_own"
on public.record_sources for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.record_sources to authenticated;
grant insert (user_id, kind, fhir_base_url, display_name, status)
on table public.record_sources to authenticated;
grant update (display_name, status, last_synced_at)
on table public.record_sources to authenticated;

-- Imports.
create policy "record_imports_select_own"
on public.record_imports for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "record_imports_insert_own"
on public.record_imports for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "record_imports_update_own"
on public.record_imports for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.record_imports to authenticated;
grant insert (user_id, source_id, status)
on table public.record_imports to authenticated;
grant update (status, finished_at, counts)
on table public.record_imports to authenticated;

-- Items.
create policy "record_items_select_own"
on public.record_items for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "record_items_insert_own"
on public.record_items for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "record_items_update_own"
on public.record_items for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.record_items to authenticated;
grant insert (user_id, source_id, import_id, resource_type, fhir_id, category, code_system, code,
  display, value_num, value_text, unit_ucum, effective_at, status, dedupe_key)
on table public.record_items to authenticated;
grant update (status) on table public.record_items to authenticated;

-- Routes: an accepted item of the caller, a category the programme receives,
-- and the enrolment's live records_import consent.
create policy "record_routes_select_own"
on public.record_routes for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "record_routes_insert_own"
on public.record_routes for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.has_consent(enrolment_id, 'records_import') and
  exists (
    select 1
    from public.record_items as i
    join public.programmes as p on p.code = record_routes.programme_code
    where i.id = record_routes.record_item_id
      and i.user_id = (select auth.uid())
      and i.status = 'accepted'
      and i.category = any (p.receives_resources)
  ) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.record_routes to authenticated;
grant insert (record_item_id, user_id, enrolment_id, programme_code)
on table public.record_routes to authenticated;

-- Truncate guards ------------------------------------------------------------------

create function public.record_rows_truncate_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH028',
    message = 'Health records are removed only with their source or account',
    hint = 'record_rows_delete_only';
end;
$$;

revoke all on function public.record_rows_truncate_guard()
from public, anon, authenticated, service_role;

create trigger record_sources_truncate_guard
before truncate on public.record_sources
for each statement execute function public.record_rows_truncate_guard();

create trigger record_imports_truncate_guard
before truncate on public.record_imports
for each statement execute function public.record_rows_truncate_guard();

create trigger record_items_truncate_guard
before truncate on public.record_items
for each statement execute function public.record_rows_truncate_guard();

create trigger record_routes_truncate_guard
before truncate on public.record_routes
for each statement execute function public.record_rows_truncate_guard();

alter table public.record_sources
enable always trigger record_sources_truncate_guard;
alter table public.record_imports
enable always trigger record_imports_truncate_guard;
alter table public.record_items
enable always trigger record_items_truncate_guard;
alter table public.record_routes
enable always trigger record_routes_truncate_guard;

revoke truncate on public.record_sources, public.record_imports, public.record_items,
  public.record_routes
from public, anon, authenticated, thsync;

-- Deleting one source's imported data ---------------------------------------------------

create function public.delete_record_source_items(p_source_id uuid, p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  v_source_id uuid;
  deleted_record_routes integer := 0;
  deleted_record_items integer := 0;
  deleted_record_imports integer := 0;
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

  select s.id
  into v_source_id
  from public.record_sources as s
  where s.id = p_source_id
    and s.user_id = caller_id
  for update;
  if not found then
    raise exception using errcode = 'TH029',
      message = 'Record source not found',
      hint = 'record_source_not_found';
  end if;

  delete from public.record_routes
  where user_id = caller_id
    and record_item_id in (
      select i.id from public.record_items as i
      where i.user_id = caller_id and i.source_id = v_source_id
    );
  get diagnostics deleted_record_routes = row_count;
  delete from public.record_items
  where user_id = caller_id and source_id = v_source_id;
  get diagnostics deleted_record_items = row_count;
  delete from public.record_imports
  where user_id = caller_id and source_id = v_source_id;
  get diagnostics deleted_record_imports = row_count;

  return jsonb_build_object(
    'record_routes', deleted_record_routes,
    'record_items', deleted_record_items,
    'record_imports', deleted_record_imports
  );
end;
$$;

revoke all on function public.delete_record_source_items(uuid, text)
from public, anon, authenticated, service_role;
grant execute on function public.delete_record_source_items(uuid, text) to authenticated;

-- Account deletion ----------------------------------------------------------------
-- delete_my_app_data also deletes and counts the four member tables, children
-- first, before the consents and enrolments. Everything else is unchanged; its
-- owner, privileges and comment are kept.
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
  deleted_record_routes integer := 0;
  deleted_record_items integer := 0;
  deleted_record_imports integer := 0;
  deleted_record_sources integer := 0;
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
  delete from public.record_routes where user_id = caller_id;
  get diagnostics deleted_record_routes = row_count;
  delete from public.record_items where user_id = caller_id;
  get diagnostics deleted_record_items = row_count;
  delete from public.record_imports where user_id = caller_id;
  get diagnostics deleted_record_imports = row_count;
  delete from public.record_sources where user_id = caller_id;
  get diagnostics deleted_record_sources = row_count;
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
    'wellbeing_baseline', deleted_wellbeing_baseline,
    'record_routes', deleted_record_routes,
    'record_items', deleted_record_items,
    'record_imports', deleted_record_imports,
    'record_sources', deleted_record_sources
  );
end;
$$;

-- Delete now ------------------------------------------------------------------------
-- delete_enrolment_now also deletes and counts the enrolment's routes (imported
-- items stay: they are account-level records). Everything else is unchanged;
-- its owner and privileges are kept.
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
  deleted_record_routes integer := 0;
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
  delete from public.record_routes where user_id = caller_id and enrolment_id = p_enrolment_id;
  get diagnostics deleted_record_routes = row_count;
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
    'programme_reminders', deleted_programme_reminders,
    'record_routes', deleted_record_routes
  );
end;
$$;

commit;
