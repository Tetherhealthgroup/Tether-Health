begin;

-- Consent documents are published only by reviewed migrations.
--
-- * consent_documents_guard now also runs before delete and before truncate:
--   only a role that bypasses row-level security removes a document (TH015),
--   and the foreign keys from programme_consents and account_consents still
--   refuse to remove a document that a consent references (23503).
-- * service_role keeps select on public.consent_documents and loses every
--   other table privilege, so documents are added, changed and removed only
--   by migrations.
-- * Every locale of a version takes effect at the same time. That rule moves
--   from the row trigger to statement triggers that run after each insert or
--   update statement, so one update can move every locale of a version no
--   consent references to a new effective_from, while any statement that
--   leaves the locales of a version with different effective_from values is
--   refused (TH015). The rest of the guard is unchanged.

create or replace function public.consent_documents_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- The checks below read consent_documents, programme_consents and
  -- account_consents, which have forced row-level security. A role subject to
  -- it might not see every row, so it is refused outright, for every write.
  if not exists (
    select 1 from pg_catalog.pg_roles as r
    where r.rolname = current_user and (r.rolsuper or r.rolbypassrls)
  ) then
    raise exception using errcode = 'TH015',
      message = 'Consent documents are changed only by a role that bypasses row-level security',
      hint = 'consent_document_immutable';
  end if;

  -- A document no consent references may be removed; the foreign keys from
  -- the consent tables refuse the others.
  if tg_op = 'DELETE' then
    return old;
  end if;
  if tg_op = 'TRUNCATE' then
    return null;
  end if;

  if tg_op = 'UPDATE' then
    if new.purpose is distinct from old.purpose or
       new.version is distinct from old.version or
       new.locale is distinct from old.locale or
       new.body is distinct from old.body then
      raise exception using errcode = 'TH015',
        message = 'Consent documents are immutable, publish a new version',
        hint = 'consent_document_immutable';
    end if;
    -- An approval is recorded once.
    if old.approved_ref is not null and
       new.approved_ref is distinct from old.approved_ref then
      raise exception using errcode = 'TH015',
        message = 'Consent documents are immutable, publish a new version',
        hint = 'consent_document_immutable';
    end if;
    -- What a granted consent relied on stays fixed. retired_at may change.
    if (new.cascades_optional is distinct from old.cascades_optional or
        new.effective_from is distinct from old.effective_from) and (
      exists (
        select 1 from public.programme_consents as c
        where c.purpose = old.purpose and c.consent_version = old.version
          and c.locale = old.locale
      ) or exists (
        select 1 from public.account_consents as c
        where c.purpose = old.purpose and c.consent_version = old.version
          and c.locale = old.locale
      )
    ) then
      raise exception using errcode = 'TH015',
        message = 'Consent documents are immutable, publish a new version',
        hint = 'consent_document_immutable';
    end if;
  end if;

  new.body_sha256 = pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(new.body, 'UTF8')), 'hex'
  );
  return new;
end;
$$;

-- Runs once per insert or update statement, after every row is written:
-- each document the statement wrote must share effective_from with every
-- other locale of its version. consent_documents_guard has already refused
-- a writer that does not bypass row-level security, so this sees every row.
create function public.consent_documents_check_effective_from()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if exists (
    select 1
    from written_documents as w
    join public.consent_documents as d
      on d.purpose = w.purpose and d.version = w.version
    where d.locale <> w.locale and d.effective_from <> w.effective_from
  ) then
    raise exception using errcode = 'TH015',
      message = 'A consent document version takes effect at the same time in every locale',
      hint = 'consent_document_immutable';
  end if;
  return null;
end;
$$;

drop trigger consent_documents_guard on public.consent_documents;
create trigger consent_documents_guard
before insert or update or delete on public.consent_documents
for each row execute function public.consent_documents_guard();

create trigger consent_documents_guard_truncate
before truncate on public.consent_documents
for each statement execute function public.consent_documents_guard();

-- A trigger with a transition table has one event, hence two triggers.
create trigger consent_documents_same_effective_from_insert
after insert on public.consent_documents
referencing new table as written_documents
for each statement execute function public.consent_documents_check_effective_from();

create trigger consent_documents_same_effective_from_update
after update on public.consent_documents
referencing new table as written_documents
for each statement execute function public.consent_documents_check_effective_from();

-- Privileges ---------------------------------------------------------------------

revoke all on table public.consent_documents from service_role;
grant select on table public.consent_documents to service_role;

revoke all on function public.consent_documents_check_effective_from()
from public, anon, authenticated;

commit;
