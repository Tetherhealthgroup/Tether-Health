-- Staging seed. Synthetic data only. NEVER run on production.
--
-- Runs only on the staging Supabase project (docs/STAGING.md). The guard
-- below refuses unless the database setting app.environment is 'staging',
-- which docs/STAGING.md sets on the staging project only, so on any other
-- database (production included) the transaction aborts before a row is
-- written. tool/staging_db.sh seed also refuses unless the connection host
-- belongs to a host in STAGING_HOSTS (tool/release_define_check.sh).
--
-- What it adds: DRAFT consent documents, version v1-staging, for every
-- purpose and both locales. Each body starts with "[DRAFT · staging]"; none
-- is approved (approved_ref stays null) and none is consent wording. The
-- migrations' v1-draft placeholders stay; v1-staging is newer, so it becomes
-- the current document on staging. Re-running adds nothing (on conflict do
-- nothing). No member, account or health data is created here: test accounts
-- are made in the app with synthetic details only.
begin;

do $guard$
begin
  if coalesce(current_setting('app.environment', true), '') <> 'staging' then
    raise exception using
      message = 'seed_staging.sql refused: app.environment is not staging',
      hint = 'This seed runs only on the staging project; see docs/STAGING.md.';
  end if;
end
$guard$;

insert into public.consent_documents (purpose, version, locale, body, effective_from)
select p.purpose, 'v1-staging', l.locale,
  format('[DRAFT · staging] Synthetic test text for the %s consent (%s). Not approved, not consent wording, staging only.',
    p.purpose, l.locale),
  timestamptz '2026-10-22 00:00:00+00'
from unnest(array[
  'core', 'reminders', 'records_import', 'share_care_team', 'share_caregiver',
  'research', 'screen_time', 'essential', 'cross_program_insights', 'diagnostics'
]) as p(purpose)
cross join unnest(array['en', 'es']) as l(locale)
on conflict (purpose, version, locale) do nothing;

commit;
