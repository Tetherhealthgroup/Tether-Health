begin;

-- service_role holds nothing in schema public except select on
-- public.consent_documents.
--
-- * The API uses the service key only for Auth admin (deleting an account's
--   identity) and Storage (removing avatar objects). Its table and function
--   calls in public go through PostgREST as authenticated, with the member's
--   token, so service_role needs no privilege on public tables or functions.
-- * Deleting an account's Auth identity removes its rows in public through
--   foreign-key cascades, which run as the table owner.
-- * Tables, functions and sequences that postgres creates in public later
--   grant service_role nothing (default privileges).
-- * service_role keeps usage on schema public and holds no create.
-- * On storage.objects and storage.buckets service_role keeps select,
--   insert, update and delete, which the Storage API uses, and loses trigger,
--   truncate and references. auth is not changed.
-- * anon, authenticated and thsync are not changed.

revoke all on all tables in schema public from service_role;
revoke all on all sequences in schema public from service_role;
grant select on table public.consent_documents to service_role;

revoke all on all functions in schema public from service_role;

revoke create on schema public from service_role;

alter default privileges for role postgres in schema public
revoke all on tables from service_role;
alter default privileges for role postgres in schema public
revoke all on functions from service_role;
alter default privileges for role postgres in schema public
revoke all on sequences from service_role;

revoke trigger, truncate, references on storage.objects, storage.buckets
from service_role;

commit;
