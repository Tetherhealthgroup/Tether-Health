begin;

-- Sync rows are removed only by row deletes, together with their programme
-- or account.
--
-- * A statement trigger on public.sync_account, public.sync_area,
--   public.sync_answer and public.sync_lapse refuses TRUNCATE for every
--   role, superuser included; the guard's code is TH019. TRUNCATE skips
--   row-level checks. A TRUNCATE ... CASCADE of another table that would
--   cascade into the sync tables is refused as well, and their rows stay; it
--   reports the code of the first guard that fires, which may be another
--   table's.
-- * The guards fire in every session mode.
-- * PUBLIC, anon, authenticated and thsync hold no truncate privilege on the
--   sync tables. Their other privileges are unchanged.
-- * Sync rows are removed by DELETE only: delete_my_app_data, and the
--   foreign-key cascades when an enrolment or an account is deleted. Nothing
--   in this migration changes them.

create function public.sync_truncate_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH019',
    message = 'Sync rows are removed only with their enrolment or account',
    hint = 'sync_rows_delete_only';
end;
$$;

create trigger sync_account_truncate_guard
before truncate on public.sync_account
for each statement execute function public.sync_truncate_guard();

create trigger sync_area_truncate_guard
before truncate on public.sync_area
for each statement execute function public.sync_truncate_guard();

create trigger sync_answer_truncate_guard
before truncate on public.sync_answer
for each statement execute function public.sync_truncate_guard();

create trigger sync_lapse_truncate_guard
before truncate on public.sync_lapse
for each statement execute function public.sync_truncate_guard();

alter table public.sync_account
enable always trigger sync_account_truncate_guard;
alter table public.sync_area
enable always trigger sync_area_truncate_guard;
alter table public.sync_answer
enable always trigger sync_answer_truncate_guard;
alter table public.sync_lapse
enable always trigger sync_lapse_truncate_guard;

-- Privileges ---------------------------------------------------------------------

revoke all on function public.sync_truncate_guard()
from public, anon, authenticated;

revoke truncate on public.sync_account, public.sync_area, public.sync_answer, public.sync_lapse
from public, anon, authenticated, thsync;

commit;
