begin;

-- Members can no longer call public.delete_my_app_data(p_confirmation)
-- directly. Only its owner may execute it. Members delete their data through
-- public.delete_my_account, which runs as that owner, calls this function and
-- also deletes the Auth identity.
--
-- * The function body, signature, owner and every other object are unchanged.
-- * The function comment is replaced: it described identity deletion as a
--   separate operation, which delete_my_account now performs.

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;

comment on function public.delete_my_app_data(text) is
  'Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.';

commit;
