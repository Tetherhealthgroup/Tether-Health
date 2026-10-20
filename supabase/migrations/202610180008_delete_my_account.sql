begin;

-- Account deletion for the signed-in member, identity included, in one
-- database call made with the member's own token.
--
-- * public.delete_my_account(p_confirmation) takes no user id: the caller is
--   auth.uid(). It refuses, in this order: no caller (42501); a sync service
--   session (TH010); a confirmation other than 'DELETE' (23514); a sign-in
--   older than 600 seconds, or more than 60 seconds in the future, by the
--   newest timestamp in the token's amr claim, or no such timestamp (TH017);
--   any avatar object still stored under the caller's folder (TH016). Avatar
--   objects are removed through the Storage API before this call; this
--   function never deletes storage rows.
-- * It then calls delete_my_app_data, unchanged, which still requires
--   begin_account_deletion first (23514) and deletes every member table, and
--   deletes the caller's auth.users row. If that row still exists afterwards
--   it raises TH018. It returns the counts delete_my_app_data returned.
-- * Everything runs in the caller's transaction: data and identity are
--   deleted together or not at all. A repeat after a completed deletion
--   returns zero counts.
-- * Only authenticated may execute it. begin_account_deletion,
--   delete_my_app_data, the avatar policies and the auth and storage schemas
--   are not changed.

create function public.delete_my_account(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  newest_sign_in numeric;
  sign_in_age numeric;
  counts jsonb;
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

  -- Avatar objects must already be gone.
  if exists (
    select 1
    from storage.objects
    where bucket_id = 'avatars'
      and (storage.foldername(name))[1] = caller_id::text
  ) then
    raise exception using errcode = 'TH016',
      message = 'Avatar objects must be removed before the account is deleted',
      hint = 'avatar_objects_remain';
  end if;

  counts := public.delete_my_app_data(p_confirmation);

  delete from auth.users where id = caller_id;
  if exists (select 1 from auth.users where id = caller_id) then
    raise exception using errcode = 'TH018',
      message = 'The account identity was not deleted',
      hint = 'auth_identity_not_deleted';
  end if;

  return counts;
end;
$$;

revoke all on function public.delete_my_account(text)
from public, anon, authenticated, service_role;
grant execute on function public.delete_my_account(text) to authenticated;

commit;
