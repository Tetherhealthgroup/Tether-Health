-- Minimal stand-ins for the parts of a Supabase database the migrations in
-- supabase/migrations rely on, so they can be applied to a plain PostgreSQL
-- server (a CI service container, or a local scratch server).
--
-- It is NOT the Supabase image: auth and storage are reduced to the objects
-- the migrations reference, and there is no PostgREST, GoTrue or Supavisor.
-- Run as a superuser on a fresh, empty database. The roles are cluster-wide,
-- so they are created only when absent.

do $roles$
begin
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  -- As in Supabase, service_role bypasses row-level security.
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
  -- The PostgREST login role, as in Supabase.
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticator') then
    create role authenticator noinherit login;
  end if;
end;
$roles$;

grant anon, authenticated, service_role to authenticator;
grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
grant create on schema public to service_role;

create schema auth;
create table auth.users (
  id uuid primary key,
  email text,
  aud varchar(255),
  role varchar(255)
);
create function auth.uid() returns uuid language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant execute on function auth.jwt() to anon, authenticated;
create table auth.identities (
  id uuid primary key default gen_random_uuid(),
  provider_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  identity_data jsonb not null,
  provider text not null,
  unique (provider_id, provider)
);
create table auth.sessions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade
);

create schema storage;
create table storage.buckets (
  id text primary key,
  name text,
  public boolean,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text,
  owner uuid
);
alter table storage.objects enable row level security;
create function storage.foldername(name text) returns text[]
  language sql immutable as $$ select string_to_array(name, '/') $$;
grant usage on schema storage to anon, authenticated, service_role;
grant all on storage.objects, storage.buckets to anon, authenticated, service_role;
