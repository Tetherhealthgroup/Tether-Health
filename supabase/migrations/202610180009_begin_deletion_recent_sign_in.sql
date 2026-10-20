begin;

-- Starting account deletion requires a recent sign-in.
--
-- * public.begin_account_deletion(p_confirmation) now refuses, after its
--   existing checks (no caller, 42501; a sync service session, TH009; a
--   confirmation other than 'DELETE', 23514) and before it sets
--   profiles.account_deletion_started_at, a sign-in older than 600 seconds,
--   or more than 60 seconds in the future, by the newest timestamp in the
--   token's amr claim, or no such timestamp (TH017). The check is the same
--   as delete_my_account's. A refusal sets nothing.
-- * Everything else is unchanged: the signature, security definer, the empty
--   search_path, the owner and the privileges (create or replace keeps them;
--   only authenticated may execute it).

create or replace function public.begin_account_deletion(p_confirmation text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  newest_sign_in numeric;
  sign_in_age numeric;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH009',
      message = 'Account deletion goes through the API',
      hint = 'deletion_via_api_only';
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

  -- The update conflicts with avatar_write_allowed's row lock. Its committed
  -- timestamp is durable across API/storage failures and idempotent retries.
  update public.profiles
  set account_deletion_started_at = coalesce(account_deletion_started_at, now())
  where id = caller_id;
  return true;
end;
$$;

commit;
