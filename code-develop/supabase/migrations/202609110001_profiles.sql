begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text null,
  locale text not null default 'en',
  time_zone text not null default 'UTC',
  onboarding_completed boolean not null default false,
  avatar_path text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_check check (
    display_name is null or
    (char_length(display_name) between 1 and 80 and display_name = btrim(display_name))
  ),
  constraint profiles_locale_check check (locale in ('en', 'es')),
  constraint profiles_time_zone_check check (
    char_length(time_zone) between 1 and 64 and
    time_zone ~ '^[A-Za-z_+-]+(/[A-Za-z0-9_+.-]+)*$'
  ),
  constraint profiles_avatar_path_check check (
    avatar_path is null or
    (char_length(avatar_path) <= 512 and avatar_path like id::text || '/%')
  )
);

comment on table public.profiles is
  'Identity preferences only. Health, smoking, symptom, and clinical data are prohibited.';

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

insert into public.profiles (id)
select id from auth.users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.profiles force row level security;

create policy "profiles_select_own"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "profiles_update_own"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (display_name, locale, time_zone, onboarding_completed, avatar_path)
on table public.profiles to authenticated;

revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "avatars_select_own"
on storage.objects for select to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatars_insert_own"
on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatars_update_own"
on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "avatars_delete_own"
on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

commit;
