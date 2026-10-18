begin;

-- Focus swap, consent documents and core-consent supersession.
--
-- * public.consent_documents holds every consent text the app may show, per
--   purpose, version and locale. It is reference data: authenticated callers
--   can read it, nobody can write it through the API. A document's purpose,
--   version, locale and body never change (TH015); the database computes
--   body_sha256. approved_ref stays null until the text is approved, so a
--   release check can refuse any current document that is not approved.
--   The seeded v1-draft rows are placeholders, not consent wording.
-- * public.current_consent_documents() returns the current document per
--   purpose and locale: the latest effective_from <= now() that is not retired.
-- * The server fills in consent text. Clients send purpose, consent_version
--   and locale; a trigger copies the body of that document into consent_text
--   and refuses a version that does not exist, is not yet effective or is
--   retired (TH011). Clients can no longer write consent_text. A foreign key
--   ties each new consent row to its document. Rows stored before this
--   migration have no locale and keep the text they were stored with.
-- * public.swap_focus(p_demote, p_promote) moves one of the caller's
--   enrolments out of focus (to learn_only) and another into focus, in one
--   transaction, and checks the focus cap (TH001) before it returns.
-- * public.supersede_core_consent(p_enrolment, p_version, p_locale) replaces
--   the live core consent with one for a new document version: the old row is
--   revoked with superseded_by set to the new row. A supersession is not the
--   member revoking consent, so optional consents stay live, unless the new
--   document is marked cascades_optional. The one-live-core key is deferrable
--   so both rows can exist inside that transaction.
-- * Both functions run as the caller (row-level security applies) and refuse
--   a sync service session (TH010).

-- Consent documents --------------------------------------------------------------

create table public.consent_documents (
  purpose text not null,
  version text not null,
  locale text not null,
  body text not null,
  body_sha256 text not null,
  effective_from timestamptz not null,
  retired_at timestamptz null,
  approved_ref text null,
  cascades_optional boolean not null default false,
  created_at timestamptz not null default now(),
  constraint consent_documents_pkey primary key (purpose, version, locale),
  constraint consent_documents_purpose_check check (
    purpose in (
      'core', 'reminders', 'records_import', 'share_care_team',
      'share_caregiver', 'research', 'screen_time',
      'essential', 'cross_program_insights', 'diagnostics'
    )
  ),
  constraint consent_documents_version_check check (
    version ~ '^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$'
  ),
  constraint consent_documents_locale_check check (locale in ('en', 'es')),
  constraint consent_documents_body_check check (
    char_length(body) between 1 and 8000
  ),
  constraint consent_documents_body_sha256_check check (
    body_sha256 ~ '^[0-9a-f]{64}$'
  ),
  constraint consent_documents_retired_after_effective_check check (
    retired_at is null or retired_at > effective_from
  ),
  constraint consent_documents_approved_ref_check check (
    approved_ref is null or char_length(approved_ref) between 1 and 200
  ),
  constraint consent_documents_cascades_core_only_check check (
    not cascades_optional or purpose = 'core'
  )
);

comment on table public.consent_documents is
  'Consent texts per purpose, version and locale (reference data, no user data). Consent rows copy the body of their document. A new wording is a new version; purpose, version, locale and body never change.';
comment on column public.consent_documents.approved_ref is
  'Reference to the approval of this exact text. Null means not approved; a release must not ship while a current document is unapproved.';
comment on column public.consent_documents.cascades_optional is
  'Core documents only. True when moving to this version must also revoke the enrolment''s optional consents (supersede_core_consent does so).';

create function public.consent_documents_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and (
    new.purpose is distinct from old.purpose or
    new.version is distinct from old.version or
    new.locale is distinct from old.locale or
    new.body is distinct from old.body
  ) then
    raise exception using errcode = 'TH015',
      message = 'Consent documents are immutable; publish a new version',
      hint = 'consent_document_immutable';
  end if;
  new.body_sha256 = pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(new.body, 'UTF8')), 'hex'
  );
  return new;
end;
$$;

create trigger consent_documents_guard
before insert or update on public.consent_documents
for each row execute function public.consent_documents_guard();

-- Placeholders until approved texts exist. Not consent wording.
insert into public.consent_documents (purpose, version, locale, body, effective_from)
select p.purpose, 'v1-draft', l.locale,
  format('[DRAFT v1-draft - not approved, not for release] Placeholder for the %s consent text (%s). The approved text replaces it before release.',
    p.purpose, l.locale),
  timestamptz '2026-10-18 00:00:00+00'
from unnest(array[
  'core', 'reminders', 'records_import', 'share_care_team', 'share_caregiver',
  'research', 'screen_time', 'essential', 'cross_program_insights', 'diagnostics'
]) as p(purpose)
cross join unnest(array['en', 'es']) as l(locale);

alter table public.consent_documents enable row level security;
alter table public.consent_documents force row level security;

create policy "consent_documents_select_authenticated"
on public.consent_documents for select
to authenticated
using (true);

revoke all on table public.consent_documents from anon, authenticated;
grant select on table public.consent_documents to authenticated;

create function public.current_consent_documents()
returns setof public.consent_documents
language sql
stable
security invoker
set search_path = ''
as $$
  select distinct on (d.purpose, d.locale) d.*
  from public.consent_documents as d
  where d.effective_from <= now()
    and (d.retired_at is null or d.retired_at > now())
  order by d.purpose, d.locale, d.effective_from desc, d.version desc;
$$;

comment on function public.current_consent_documents() is
  'The current document per purpose and locale: the latest effective_from <= now() that is not retired. Security invoker.';

-- Consent rows take their text from the document --------------------------------

alter table public.programme_consents
  add column locale text null,
  add column superseded_by uuid null,
  add column live_core_enrolment_id uuid generated always as (
    case when purpose = 'core' and revoked_at is null then enrolment_id end
  ) stored,
  add constraint programme_consents_locale_check check (
    locale is null or locale in ('en', 'es')
  ),
  add constraint programme_consents_document_fkey
    foreign key (purpose, consent_version, locale)
    references public.consent_documents (purpose, version, locale),
  add constraint programme_consents_superseded_by_fkey
    foreign key (superseded_by) references public.programme_consents (id),
  add constraint programme_consents_superseded_check check (
    superseded_by is null or (
      purpose = 'core' and revoked_at is not null and superseded_by <> id
    )
  );

alter table public.account_consents
  add column locale text null,
  add constraint account_consents_locale_check check (
    locale is null or locale in ('en', 'es')
  ),
  add constraint account_consents_document_fkey
    foreign key (purpose, consent_version, locale)
    references public.consent_documents (purpose, version, locale);

comment on column public.programme_consents.locale is
  'Locale of the document shown. Null only on rows stored before consent documents existed.';
comment on column public.programme_consents.superseded_by is
  'Set when a new core document version replaced this core consent (supersede_core_consent). A superseded row is revoked without revoking the optional consents.';
comment on column public.programme_consents.live_core_enrolment_id is
  'Database managed: the enrolment id while this is the live core consent, otherwise null. Backs the deferrable one-live-core key.';
comment on column public.account_consents.locale is
  'Locale of the document shown. Null only on rows stored before consent documents existed.';

-- One live core consent per enrolment, as a deferrable key, so a supersession
-- can insert the new row before it revokes the old one. Other purposes keep
-- the partial unique index.
alter table public.programme_consents
  add constraint programme_consents_live_core_key
  unique (live_core_enrolment_id) deferrable initially immediate;

drop index public.programme_consents_live_key;
create unique index programme_consents_live_key
on public.programme_consents (enrolment_id, purpose, coalesce(recipient_ref, ''))
where revoked_at is null and purpose <> 'core';

create function public.consent_fill_text()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  document_body text;
begin
  select d.body
  into document_body
  from public.consent_documents as d
  where d.purpose = new.purpose
    and d.version = new.consent_version
    and d.locale = new.locale
    and d.effective_from <= now()
    and (d.retired_at is null or d.retired_at > now());

  if document_body is null then
    raise exception using errcode = 'TH011',
      message = 'No consent document is available for this purpose, version and locale',
      hint = 'consent_document_unavailable';
  end if;
  new.consent_text = document_body;
  return new;
end;
$$;

create trigger programme_consents_fill_text
before insert on public.programme_consents
for each row execute function public.consent_fill_text();

create trigger account_consents_fill_text
before insert on public.account_consents
for each row execute function public.consent_fill_text();

revoke insert (consent_text) on table public.programme_consents from authenticated;
revoke insert (consent_text) on table public.account_consents from authenticated;
grant insert (locale) on table public.programme_consents to authenticated;
grant insert (locale) on table public.account_consents to authenticated;
-- supersede_core_consent runs as the caller and sets superseded_by on the row
-- it revokes; programme_consents_check_supersede accepts only the live core
-- consent that replaces it.
grant update (superseded_by) on table public.programme_consents to authenticated;

-- Revocation rules -----------------------------------------------------------------

-- Unchanged, except that superseded_by may be set together with revoked_at
-- and the generated live_core_enrolment_id is not compared.
create or replace function public.consent_revoke_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.revoked_at is not null then
    raise exception using errcode = 'TH002',
      message = 'Consent is already revoked',
      hint = 'consent_already_revoked';
  end if;
  if new.revoked_at is null then
    raise exception using errcode = 'TH003',
      message = 'Consent can only be revoked',
      hint = 'consent_immutable';
  end if;
  if (to_jsonb(new) - array['revoked_at', 'superseded_by', 'live_core_enrolment_id']) is distinct from
     (to_jsonb(old) - array['revoked_at', 'superseded_by', 'live_core_enrolment_id']) then
    raise exception using errcode = 'TH003',
      message = 'Consent records are immutable',
      hint = 'consent_immutable';
  end if;
  new.revoked_at = greatest(clock_timestamp(), old.granted_at);
  return new;
end;
$$;

-- A row may name only the live core consent of the same enrolment that
-- replaces it. Without this, setting superseded_by on a plain revocation would
-- skip the cascade below.
create function public.programme_consents_check_supersede()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.programme_consents as r
    where r.id = new.superseded_by
      and r.id <> old.id
      and r.enrolment_id = old.enrolment_id
      and r.purpose = 'core'
      and r.revoked_at is null
  ) then
    raise exception using errcode = 'TH003',
      message = 'Consent records are immutable',
      hint = 'consent_immutable';
  end if;
  return new;
end;
$$;

create trigger programme_consents_check_supersede
before update of superseded_by on public.programme_consents
for each row
when (new.superseded_by is distinct from old.superseded_by)
execute function public.programme_consents_check_supersede();

-- Revoking core still switches off every other consent of the enrolment, but
-- a superseded core row (revoked with superseded_by set) does not.
drop trigger programme_consents_revoke_with_core on public.programme_consents;
create trigger programme_consents_revoke_with_core
after update of revoked_at on public.programme_consents
for each row
when (
  old.purpose = 'core' and old.revoked_at is null and new.revoked_at is not null
  and new.superseded_by is null
)
execute function public.programme_consents_revoke_with_core();

-- Focus swap ---------------------------------------------------------------------

create function public.swap_focus(p_demote uuid, p_promote uuid)
returns setof public.enrolments
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  demote_status text;
  promote_status text;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;
  if p_demote is null or p_promote is null or p_demote = p_promote then
    raise exception using errcode = 'TH013',
      message = 'A swap needs one programme in focus and another not in focus',
      hint = 'focus_swap_invalid';
  end if;

  -- Lock both rows, in id order, before reading their status.
  perform 1
  from public.enrolments
  where id in (p_demote, p_promote) and user_id = caller_id
  order by id
  for update;

  select status into demote_status
  from public.enrolments where id = p_demote and user_id = caller_id;
  select status into promote_status
  from public.enrolments where id = p_promote and user_id = caller_id;

  if demote_status is null or promote_status is null then
    raise exception using errcode = 'TH012',
      message = 'Enrolment not found',
      hint = 'enrolment_not_found';
  end if;
  if promote_status = 'left' then
    raise exception using errcode = 'TH005',
      message = 'The programme has been left',
      hint = 'enrolment_left';
  end if;
  if demote_status <> 'focus' or promote_status = 'focus' then
    raise exception using errcode = 'TH013',
      message = 'A swap needs one programme in focus and another not in focus',
      hint = 'focus_swap_invalid';
  end if;

  return query
    update public.enrolments set status = 'learn_only'
    where id = p_demote and user_id = caller_id
    returning *;
  return query
    update public.enrolments set status = 'focus'
    where id = p_promote and user_id = caller_id
    returning *;

  -- Check the focus cap now (under its per-user lock) rather than at commit,
  -- so a refused swap fails here and changes nothing.
  set constraints public.enrolments_focus_cap immediate;
  set constraints public.enrolments_focus_cap deferred;
end;
$$;

comment on function public.swap_focus(uuid, uuid) is
  'Moves p_demote from focus to learn_only and p_promote (not left, not in focus) to focus, in one transaction; returns both rows. Security invoker; refuses a sync service session (TH010).';

-- Core consent supersession --------------------------------------------------------

create function public.supersede_core_consent(
  p_enrolment uuid,
  p_version text,
  p_locale text
)
returns setof public.programme_consents
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  enrolment_status text;
  old_row public.programme_consents;
  new_row public.programme_consents;
  doc public.consent_documents;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;

  -- The share lock waits for, and then blocks, a concurrent status change
  -- such as leaving.
  select e.status
  into enrolment_status
  from public.enrolments as e
  where e.id = p_enrolment and e.user_id = caller_id
  for share;

  if enrolment_status is null then
    raise exception using errcode = 'TH012',
      message = 'Enrolment not found',
      hint = 'enrolment_not_found';
  end if;
  if enrolment_status = 'left' then
    raise exception using errcode = 'TH005',
      message = 'The programme has been left',
      hint = 'enrolment_left';
  end if;
  if not public.deletion_barrier_open() then
    raise exception using errcode = 'TH006',
      message = 'Account deletion has started',
      hint = 'deletion_in_progress';
  end if;

  select c.*
  into old_row
  from public.programme_consents as c
  where c.enrolment_id = p_enrolment
    and c.purpose = 'core'
    and c.revoked_at is null
  for update;

  if old_row.id is null then
    raise exception using errcode = 'TH004',
      message = 'A live core consent is required',
      hint = 'consent_requires_core';
  end if;

  select d.*
  into doc
  from public.consent_documents as d
  where d.purpose = 'core'
    and d.version = p_version
    and d.locale = p_locale
    and d.effective_from <= now()
    and (d.retired_at is null or d.retired_at > now());

  if doc.version is null then
    raise exception using errcode = 'TH011',
      message = 'No consent document is available for this purpose, version and locale',
      hint = 'consent_document_unavailable';
  end if;
  if old_row.consent_version = p_version and old_row.locale is not distinct from p_locale then
    raise exception using errcode = 'TH014',
      message = 'The core consent is already on this version',
      hint = 'consent_version_unchanged';
  end if;

  set constraints public.programme_consents_live_core_key deferred;

  -- consent_fill_text sets consent_text from the document.
  insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
  values (p_enrolment, 'core', doc.version, doc.locale)
  returning * into new_row;

  update public.programme_consents
  set revoked_at = now(), superseded_by = new_row.id
  where id = old_row.id
  returning * into old_row;

  if doc.cascades_optional then
    update public.programme_consents
    set revoked_at = now()
    where enrolment_id = p_enrolment
      and purpose <> 'core'
      and revoked_at is null;
  end if;

  set constraints public.programme_consents_live_core_key immediate;

  return next old_row;
  return next new_row;
end;
$$;

comment on function public.supersede_core_consent(uuid, text, text) is
  'Replaces the caller''s live core consent on an enrolment with one for core document p_version/p_locale, in one transaction. The old row is revoked with superseded_by set; optional consents stay live unless the document cascades_optional. Returns the old row, then the new one. Security invoker; refuses a sync service session (TH010).';

-- Privileges ---------------------------------------------------------------------

revoke all on function public.consent_documents_guard()
from public, anon, authenticated;
revoke all on function public.consent_fill_text()
from public, anon, authenticated;
revoke all on function public.consent_revoke_only()
from public, anon, authenticated;
revoke all on function public.programme_consents_check_supersede()
from public, anon, authenticated;
revoke all on function public.current_consent_documents()
from public, anon, authenticated;
grant execute on function public.current_consent_documents() to authenticated;
revoke all on function public.swap_focus(uuid, uuid)
from public, anon, authenticated;
grant execute on function public.swap_focus(uuid, uuid) to authenticated;
revoke all on function public.supersede_core_consent(uuid, text, text)
from public, anon, authenticated;
grant execute on function public.supersede_core_consent(uuid, text, text)
to authenticated;

commit;
