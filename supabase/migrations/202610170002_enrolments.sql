begin;

-- Programmes, enrolments and consents.
--
-- * public.programmes is read-only reference data: the 11 programmes of the
--   tether_ui spec, keyed by a stable two-letter code.
-- * Programme health data hangs off public.enrolments, never off the account.
--   Later tables reference enrolments(id) on delete cascade and scope RLS
--   through enrolments.user_id = auth.uid().
-- * Consent is recorded per enrolment x purpose x recipient
--   (public.programme_consents). Account-level items that are not about any
--   programme live in public.account_consents. Consent rows keep the version
--   and the exact wording, and are never edited except to revoke them.
-- * public.has_consent() is the single check later policies use.
-- * delete_my_app_data also deletes the caller's enrolments and consents.
-- * Leaving a programme keeps its data until the member deletes it or deletes
--   the account; there is no automatic purge.
-- * Leaving, or revoking an enrolment's core consent, revokes its optional
--   consents. After rejoining they must be granted again.
-- * At most two enrolments per user are in focus (checked at commit, so a
--   swap works in one transaction).
-- * New enrolments and consents are refused once account deletion has started
--   (profiles.account_deletion_started_at) or the profile is gone, through
--   public.deletion_barrier_open(), which programme-data tables also use.

create table public.programmes (
  code text primary key,
  slug text not null unique,
  name text not null,
  area text not null,
  archetype text not null,
  receives_resources text[] not null default '{}',
  constraint programmes_code_check check (code ~ '^[a-z]{2}$'),
  constraint programmes_slug_check check (slug ~ '^[a-z][a-z0-9_]{1,31}$'),
  constraint programmes_name_check check (char_length(name) between 1 and 80),
  constraint programmes_area_check check (char_length(area) between 1 and 80),
  constraint programmes_archetype_check check (
    char_length(archetype) between 1 and 80
  ),
  constraint programmes_receives_resources_check check (
    cardinality(receives_resources) <= 32 and
    array_position(receives_resources, null) is null
  )
);

comment on table public.programmes is
  'Programme catalogue (reference data, no user data). Codes are stable identifiers used by enrolments.';
comment on column public.programmes.receives_resources is
  'Record categories a programme may receive from health records, routed only with that enrolment''s records_import consent. Empty means the programme never receives records.';

insert into public.programmes (code, slug, name, area, archetype, receives_resources)
values
  ('bf', 'breathefree', 'BreatheFree', 'Tobacco & nicotine', 'Quit / Reduce',
   array['smoking_status']),
  ('sf', 'scrollfree', 'ScrollFree', 'Social media use', 'Quit / Reduce',
   array[]::text[]),
  ('ca', 'clearair', 'ClearAir', 'Respiratory health', 'Manage',
   array[]::text[]),
  ('hw', 'heartwise', 'Heartwise', 'Cardiovascular health', 'Manage',
   array['blood_pressure', 'lipids']),
  ('st', 'steady', 'Steady', 'Diabetes & metabolic health', 'Manage',
   array['a1c', 'glucose']),
  ('re', 'renew', 'Renew', 'Kidney & liver health', 'Manage',
   array['egfr']),
  ('nu', 'nourish', 'Nourish', 'Obesity & nutrition', 'Build habits',
   array[]::text[]),
  ('sd', 'stride', 'Stride', 'Healthy aging', 'Build habits',
   array[]::text[]),
  ('ea', 'ease', 'Ease', 'Mental & behavioral health', 'Support',
   array[]::text[]),
  ('ck', 'checkup', 'Checkup', 'Preventive health', 'Prevent',
   array['immunizations']),
  ('be', 'beacon', 'Beacon', 'Cancer', 'Prevent',
   array[]::text[]);

alter table public.programmes enable row level security;
alter table public.programmes force row level security;

create policy "programmes_select_authenticated"
on public.programmes for select
to authenticated
using (true);

revoke all on table public.programmes from anon, authenticated;
grant select on table public.programmes to authenticated;

create table public.enrolments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  programme_code text not null references public.programmes(code),
  status text not null default 'focus',
  mode text null,
  joined_at timestamptz not null default now(),
  left_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint enrolments_user_programme_key unique (user_id, programme_code),
  constraint enrolments_status_check check (
    status in ('focus', 'learn_only', 'paused', 'left')
  ),
  constraint enrolments_mode_check check (
    mode is null or (
      programme_code in ('bf', 'sf') and mode in ('quit', 'reduce')
    )
  ),
  constraint enrolments_left_state_check check (
    (status = 'left') = (left_at is not null)
  )
);

comment on table public.enrolments is
  'One row per user and programme. Programme health data references this row and is deleted with it. Leaving keeps the row and its data (status left) until the member deletes it or the account.';
comment on column public.enrolments.left_at is
  'Set by the database when the status changes to left; cleared on rejoin.';

create trigger enrolments_set_updated_at
before update on public.enrolments
for each row execute function public.set_updated_at();

create function public.enrolments_manage_leaving()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'left' and old.status is distinct from 'left' then
    new.left_at = now();
  elsif new.status <> 'left' then
    new.left_at = null;
  else
    new.left_at = old.left_at;
  end if;
  return new;
end;
$$;

create trigger enrolments_manage_leaving
before update on public.enrolments
for each row execute function public.enrolments_manage_leaving();

-- Shared deletion barrier for insert checks on enrolments, consents and
-- programme-data tables. Takes a share lock on the caller's profile row, so
-- begin_account_deletion (which updates that row) waits for in-flight inserts,
-- and inserts that arrive later see the committed barrier.
create function public.deletion_barrier_open()
returns boolean
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  barrier_open boolean := false;
begin
  if caller_id is null then
    return false;
  end if;

  select p.account_deletion_started_at is null
  into barrier_open
  from public.profiles as p
  where p.id = caller_id
  for share;

  return coalesce(barrier_open, false);
end;
$$;

comment on function public.deletion_barrier_open() is
  'True while the caller''s profile exists and account deletion has not started. Use in the insert check of every table that holds the caller''s data.';

create function public.enrolments_focus_cap()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  focus_count integer;
begin
  perform pg_advisory_xact_lock(
    hashtextextended('enrolments.focus:' || new.user_id::text, 0)
  );

  select count(*)
  into focus_count
  from public.enrolments
  where user_id = new.user_id and status = 'focus';

  if focus_count > 2 then
    raise check_violation using message = 'At most two programmes can be in focus';
  end if;
  return null;
end;
$$;

create constraint trigger enrolments_focus_cap
after insert or update of status on public.enrolments
deferrable initially deferred
for each row
when (new.status = 'focus')
execute function public.enrolments_focus_cap();

alter table public.enrolments enable row level security;
alter table public.enrolments force row level security;

create policy "enrolments_select_own"
on public.enrolments for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "enrolments_insert_own"
on public.enrolments for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open()
);

create policy "enrolments_update_own"
on public.enrolments for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "enrolments_delete_own"
on public.enrolments for delete
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.enrolments from anon, authenticated;
grant select, delete on table public.enrolments to authenticated;
grant insert (user_id, programme_code, status, mode)
on table public.enrolments to authenticated;
grant update (status, mode) on table public.enrolments to authenticated;

create table public.programme_consents (
  id uuid primary key default gen_random_uuid(),
  enrolment_id uuid not null references public.enrolments(id) on delete cascade,
  purpose text not null,
  recipient_ref text null,
  consent_version text not null,
  consent_text text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz null,
  constraint programme_consents_purpose_check check (
    purpose in (
      'core', 'reminders', 'records_import', 'share_care_team',
      'share_caregiver', 'research', 'screen_time'
    )
  ),
  constraint programme_consents_recipient_check check (
    (purpose in ('share_care_team', 'share_caregiver')) =
    (recipient_ref is not null)
  ),
  constraint programme_consents_recipient_ref_check check (
    recipient_ref is null or char_length(recipient_ref) between 1 and 200
  ),
  constraint programme_consents_version_check check (
    consent_version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$'
  ),
  constraint programme_consents_text_check check (
    char_length(consent_text) between 1 and 8000
  ),
  constraint programme_consents_revoked_after_granted_check check (
    revoked_at is null or revoked_at >= granted_at
  )
);

comment on table public.programme_consents is
  'Consent per enrolment, purpose and recipient. Keeps the version and wording shown. Rows are never edited except to revoke; a revoked row stays as history until the enrolment or account is deleted. Revoking core revokes every live consent of the enrolment; leaving revokes every live non-core consent.';

create index programme_consents_enrolment_idx
on public.programme_consents (enrolment_id);

-- One live row per enrolment, purpose and recipient. Revoked rows are outside
-- the index, so a revocation can never conflict with history.
create unique index programme_consents_live_key
on public.programme_consents (enrolment_id, purpose, coalesce(recipient_ref, ''))
where revoked_at is null;

create table public.account_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  purpose text not null,
  consent_version text not null,
  consent_text text not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz null,
  constraint account_consents_purpose_check check (
    purpose in ('essential', 'cross_program_insights', 'diagnostics')
  ),
  constraint account_consents_version_check check (
    consent_version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$'
  ),
  constraint account_consents_text_check check (
    char_length(consent_text) between 1 and 8000
  ),
  constraint account_consents_revoked_after_granted_check check (
    revoked_at is null or revoked_at >= granted_at
  )
);

comment on table public.account_consents is
  'Account-level consent items that belong to no programme. Never holds health data; programme consent is in programme_consents.';

create unique index account_consents_live_key
on public.account_consents (user_id, purpose)
where revoked_at is null;

create function public.consent_revoke_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise check_violation using message = 'Consent is already revoked';
  end if;
  if new.revoked_at is null then
    raise check_violation using message = 'Consent can only be revoked';
  end if;
  if (to_jsonb(new) - 'revoked_at') is distinct from
     (to_jsonb(old) - 'revoked_at') then
    raise check_violation using message = 'Consent records are immutable';
  end if;
  new.revoked_at = greatest(clock_timestamp(), old.granted_at);
  return new;
end;
$$;

create trigger programme_consents_revoke_only
before update on public.programme_consents
for each row execute function public.consent_revoke_only();

create trigger account_consents_revoke_only
before update on public.account_consents
for each row execute function public.consent_revoke_only();

-- Revoking core switches off every other consent of the enrolment, so a later
-- core grant cannot revive old optional grants.
create function public.programme_consents_revoke_with_core()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.programme_consents
  set revoked_at = new.revoked_at
  where enrolment_id = new.enrolment_id
    and revoked_at is null;
  return null;
end;
$$;

create trigger programme_consents_revoke_with_core
after update of revoked_at on public.programme_consents
for each row
when (
  old.purpose = 'core' and old.revoked_at is null and new.revoked_at is not null
)
execute function public.programme_consents_revoke_with_core();

-- Leaving switches off every optional consent of the enrolment. Core stays
-- live but grants nothing while the enrolment is left (see has_consent).
create function public.enrolments_revoke_on_leave()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.programme_consents
  set revoked_at = now()
  where enrolment_id = new.id
    and purpose <> 'core'
    and revoked_at is null;
  return null;
end;
$$;

create trigger enrolments_revoke_on_leave
after update of status on public.enrolments
for each row
when (new.status = 'left' and old.status is distinct from 'left')
execute function public.enrolments_revoke_on_leave();

create function public.has_consent(
  p_enrolment_id uuid,
  p_purpose text,
  p_recipient_ref text default null
)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from public.enrolments as e
    join public.profiles as p on p.id = e.user_id
    join public.programme_consents as c on c.enrolment_id = e.id
    where e.id = p_enrolment_id
      and e.user_id = (select auth.uid())
      and e.status <> 'left'
      and p.account_deletion_started_at is null
      and c.purpose = p_purpose
      and c.recipient_ref is not distinct from p_recipient_ref
      and c.revoked_at is null
  ) and (
    p_purpose = 'core' or exists (
      select 1
      from public.programme_consents as core
      where core.enrolment_id = p_enrolment_id
        and core.purpose = 'core'
        and core.recipient_ref is null
        and core.revoked_at is null
    )
  );
$$;

comment on function public.has_consent(uuid, text, text) is
  'True only when the caller owns the enrolment, it is not left, account deletion has not started, a live consent exists for the purpose and recipient, and (for any purpose but core) the enrolment''s core consent is live. Security invoker: RLS still applies.';

alter table public.programme_consents enable row level security;
alter table public.programme_consents force row level security;

create policy "programme_consents_select_own"
on public.programme_consents for select
to authenticated
using (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
  )
);

create policy "programme_consents_insert_own"
on public.programme_consents for insert
to authenticated
with check (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
      and e.status <> 'left'
  ) and public.deletion_barrier_open() and (
    programme_consents.purpose = 'core' or
    public.has_consent(programme_consents.enrolment_id, 'core')
  )
);

create policy "programme_consents_update_own"
on public.programme_consents for update
to authenticated
using (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.enrolments as e
    where e.id = programme_consents.enrolment_id
      and e.user_id = (select auth.uid())
  )
);

revoke all on table public.programme_consents from anon, authenticated;
grant select on table public.programme_consents to authenticated;
grant insert (enrolment_id, purpose, recipient_ref, consent_version, consent_text)
on table public.programme_consents to authenticated;
grant update (revoked_at) on table public.programme_consents to authenticated;

alter table public.account_consents enable row level security;
alter table public.account_consents force row level security;

create policy "account_consents_select_own"
on public.account_consents for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "account_consents_insert_own"
on public.account_consents for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  public.deletion_barrier_open()
);

create policy "account_consents_update_own"
on public.account_consents for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on table public.account_consents from anon, authenticated;
grant select on table public.account_consents to authenticated;
grant insert (user_id, purpose, consent_version, consent_text)
on table public.account_consents to authenticated;
grant update (revoked_at) on table public.account_consents to authenticated;

revoke all on function public.enrolments_manage_leaving()
from public, anon, authenticated;
revoke all on function public.enrolments_focus_cap()
from public, anon, authenticated;
revoke all on function public.enrolments_revoke_on_leave()
from public, anon, authenticated;
revoke all on function public.programme_consents_revoke_with_core()
from public, anon, authenticated;
revoke all on function public.deletion_barrier_open()
from public, anon, authenticated;
grant execute on function public.deletion_barrier_open() to authenticated;
revoke all on function public.consent_revoke_only()
from public, anon, authenticated;
revoke all on function public.has_consent(uuid, text, text)
from public, anon, authenticated;
grant execute on function public.has_consent(uuid, text, text) to authenticated;

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
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
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
    'account_consents', deleted_account_consents
  );
end;
$$;

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;
grant execute on function public.delete_my_app_data(text) to authenticated;

commit;
