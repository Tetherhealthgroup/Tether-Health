begin;

alter table public.profiles
add column account_deletion_started_at timestamptz null;

comment on column public.profiles.account_deletion_started_at is
  'Server-managed durable write barrier set before complete account cleanup.';

create function public.avatar_write_allowed(object_name text)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  write_allowed boolean := false;
begin
  if caller_id is null then
    return false;
  end if;

  -- Hold a row lock through the Storage write transaction. Beginning account
  -- deletion updates this same row, so it waits for earlier uploads to finish;
  -- uploads that arrive later wait and then observe the committed barrier.
  select p.account_deletion_started_at is null
  into write_allowed
  from public.profiles as p
  where p.id = caller_id
  for share;

  return coalesce(write_allowed, false)
    and (storage.foldername(object_name))[1] = caller_id::text;
end;
$$;

revoke all on function public.avatar_write_allowed(text)
from public, anon, authenticated;
grant execute on function public.avatar_write_allowed(text) to authenticated;

drop policy "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars' and public.avatar_write_allowed(name)
);

drop policy "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars' and public.avatar_write_allowed(name)
)
with check (
  bucket_id = 'avatars' and public.avatar_write_allowed(name)
);

create function public.begin_account_deletion(p_confirmation text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;

  -- The update conflicts with avatar_write_allowed's row lock. Its committed
  -- timestamp is durable across API/storage failures and idempotent retries.
  update public.profiles
  set account_deletion_started_at = coalesce(account_deletion_started_at, now())
  where id = caller_id;
  return true;
end;
$$;

revoke all on function public.begin_account_deletion(text)
from public, anon, authenticated;
grant execute on function public.begin_account_deletion(text) to authenticated;

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

  delete from public.program_data where user_id = caller_id;
  get diagnostics deleted_program_data = row_count;
  delete from public.quit_plans where user_id = caller_id;
  get diagnostics deleted_quit_plans = row_count;
  delete from public.profiles where id = caller_id;
  get diagnostics deleted_profiles = row_count;

  return jsonb_build_object(
    'profiles', deleted_profiles,
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data
  );
end;
$$;

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;
grant execute on function public.delete_my_app_data(text) to authenticated;

commit;
