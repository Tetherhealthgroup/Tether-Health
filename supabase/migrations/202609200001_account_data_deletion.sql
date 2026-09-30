begin;

create function public.delete_my_app_data(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  deleted_profiles integer := 0;
  deleted_quit_plans integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;

  delete from public.quit_plans where user_id = caller_id;
  get diagnostics deleted_quit_plans = row_count;

  delete from public.profiles where id = caller_id;
  get diagnostics deleted_profiles = row_count;

  return jsonb_build_object(
    'profiles', deleted_profiles,
    'quit_plans', deleted_quit_plans
  );
end;
$$;

comment on function public.delete_my_app_data(text) is
  'Deletes only the authenticated caller app-owned database rows. Supabase Auth identity deletion remains a separate privileged operation.';

revoke all on function public.delete_my_app_data(text)
from public, anon, authenticated;
grant execute on function public.delete_my_app_data(text) to authenticated;

commit;
