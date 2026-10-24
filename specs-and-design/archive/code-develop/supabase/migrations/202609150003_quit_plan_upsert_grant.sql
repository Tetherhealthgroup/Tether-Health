begin;

grant update (user_id) on table public.quit_plans
to authenticated;

commit;
