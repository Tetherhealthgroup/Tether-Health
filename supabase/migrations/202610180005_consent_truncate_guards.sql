begin;

-- Consent records are removed only by row deletes.
--
-- * A statement trigger on public.programme_consents and one on
--   public.account_consents refuse TRUNCATE for every role, superuser
--   included (TH003). TRUNCATE skips the row triggers that keep consent
--   history revoke-only. A TRUNCATE ... CASCADE of a table the consent
--   tables reference (enrolments, auth.users) reaches them too, so it is
--   refused as well.
-- * Consent rows are removed by DELETE only: delete_my_app_data, and the
--   foreign-key cascades when an enrolment or an account is deleted. Nothing
--   in this migration changes them.

create function public.consent_truncate_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH003',
    message = 'Consent records are immutable',
    hint = 'consent_immutable';
end;
$$;

create trigger programme_consents_truncate_guard
before truncate on public.programme_consents
for each statement execute function public.consent_truncate_guard();

create trigger account_consents_truncate_guard
before truncate on public.account_consents
for each statement execute function public.consent_truncate_guard();

-- Privileges ---------------------------------------------------------------------

revoke all on function public.consent_truncate_guard()
from public, anon, authenticated, service_role;

commit;
