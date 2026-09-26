begin;

create table public.program_data (
  user_id uuid not null references auth.users(id) on delete cascade,
  program_id text not null,
  payload jsonb not null default '{}'::jsonb,
  revision integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, program_id),
  constraint program_data_program_check check (
    program_id in ('heartwise', 'steady', 'clearair')
  ),
  constraint program_data_payload_object_check check (
    jsonb_typeof(payload) = 'object'
  ),
  constraint program_data_payload_size_check check (
    octet_length(payload::text) <= 32768
  ),
  constraint program_data_revision_check check (
    revision between 1 and 2147483647
  )
);

comment on table public.program_data is
  'Caller-owned health module state. Never include this payload in logs.';

create trigger program_data_set_updated_at
before update on public.program_data
for each row execute function public.set_updated_at();

alter table public.program_data enable row level security;
alter table public.program_data force row level security;

create policy "program_data_select_own"
on public.program_data for select to authenticated
using ((select auth.uid()) = user_id);

create policy "program_data_insert_own"
on public.program_data for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "program_data_update_own"
on public.program_data for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "program_data_delete_own"
on public.program_data for delete to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.program_data from anon, authenticated;
grant select, insert, update, delete on table public.program_data
to authenticated;

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
