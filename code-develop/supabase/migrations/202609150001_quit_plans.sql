begin;

create function public.is_valid_support_people(value jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case
    when jsonb_typeof(value) <> 'array' then false
    when jsonb_array_length(value) > 10 then false
    else
      not exists (
        select 1
        from jsonb_array_elements(value) as entry
        where jsonb_typeof(entry) <> 'object'
          or (entry - array['id', 'name', 'relationship', 'channel', 'checkIn', 'enabled']) <> '{}'::jsonb
          or not (entry ?& array['id', 'name', 'relationship', 'channel', 'checkIn', 'enabled'])
          or jsonb_typeof(entry -> 'id') <> 'string'
          or jsonb_typeof(entry -> 'name') <> 'string'
          or jsonb_typeof(entry -> 'relationship') <> 'string'
          or jsonb_typeof(entry -> 'channel') <> 'string'
          or jsonb_typeof(entry -> 'checkIn') <> 'string'
          or jsonb_typeof(entry -> 'enabled') <> 'boolean'
          or (entry ->> 'id') !~ '^[A-Za-z0-9_-]{1,80}$'
          or char_length(entry ->> 'name') not between 1 and 80
          or (entry ->> 'name') <> btrim(entry ->> 'name')
          or char_length(entry ->> 'relationship') not between 1 and 80
          or (entry ->> 'relationship') <> btrim(entry ->> 'relationship')
          or (entry ->> 'channel') not in ('text', 'call')
          or char_length(entry ->> 'checkIn') not between 1 and 160
          or (entry ->> 'checkIn') <> btrim(entry ->> 'checkIn')
      )
      and jsonb_array_length(value) = (
        select count(distinct entry ->> 'id')
        from jsonb_array_elements(value) as entry
      )
  end;
$$;

create function public.is_unique_text_array(value text[])
returns boolean
language sql
immutable
strict
set search_path = ''
as $$
  select cardinality(value) = (
    select count(distinct item)
    from unnest(value) as item
  );
$$;

create table public.quit_plans (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  daily_cigarette_use text null,
  smoking_triggers text[] not null default '{}',
  custom_smoking_trigger text null,
  readiness_path text not null default 'prepare',
  quit_plan_path text not null default 'setQuitDate',
  quit_date date not null,
  quit_day_check_in boolean not null default true,
  quit_reasons text[] not null default '{}',
  custom_quit_reason text null,
  top_quit_reason text null,
  support_people jsonb not null default '[]'::jsonb,
  preparation_tasks text[] not null default '{}',
  treatment_support boolean not null default true,
  care_team_reminder boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint quit_plans_daily_cigarette_use_check check (
    daily_cigarette_use is null or daily_cigarette_use in (
      'notEveryDay', 'tenOrFewer', 'elevenToTwenty',
      'twentyOneToThirty', 'thirtyOneOrMore'
    )
  ),
  constraint quit_plans_smoking_triggers_check check (
    cardinality(smoking_triggers) <= 10 and
    public.is_unique_text_array(smoking_triggers) and
    smoking_triggers <@ array[
      'stress', 'afterMeals', 'driving', 'coffee', 'socialSettings',
      'workBreaks', 'alcohol', 'boredom', 'morning', 'beforeBed'
    ]::text[]
  ),
  constraint quit_plans_custom_smoking_trigger_check check (
    custom_smoking_trigger is null or (
      char_length(custom_smoking_trigger) between 1 and 120 and
      custom_smoking_trigger = btrim(custom_smoking_trigger)
    )
  ),
  constraint quit_plans_readiness_path_check check (
    readiness_path in ('prepare', 'explore', 'connect')
  ),
  constraint quit_plans_quit_plan_path_check check (
    quit_plan_path in ('setQuitDate', 'quitToday', 'reduceGradually')
  ),
  constraint quit_plans_quit_reasons_check check (
    cardinality(quit_reasons) <= 7 and
    public.is_unique_text_array(quit_reasons) and
    quit_reasons <@ array[
      'family', 'breatheEasier', 'improveHealth', 'saveMoney',
      'control', 'future', 'custom'
    ]::text[]
  ),
  constraint quit_plans_custom_quit_reason_check check (
    custom_quit_reason is null or (
      char_length(custom_quit_reason) between 1 and 160 and
      custom_quit_reason = btrim(custom_quit_reason)
    )
  ),
  constraint quit_plans_custom_reason_selection_check check (
    ('custom' = any(quit_reasons)) = (custom_quit_reason is not null)
  ),
  constraint quit_plans_top_quit_reason_check check (
    top_quit_reason is null or top_quit_reason = any(quit_reasons)
  ),
  constraint quit_plans_support_people_check check (
    public.is_valid_support_people(support_people)
  ),
  constraint quit_plans_preparation_tasks_check check (
    cardinality(preparation_tasks) <= 3 and
    public.is_unique_text_array(preparation_tasks) and
    preparation_tasks <@ array[
      'removeSupplies', 'smokeFreeSpaces', 'stockAlternatives'
    ]::text[]
  )
);

comment on table public.quit_plans is
  'Development-only quit-plan snapshot. Use synthetic data until privacy, clinical, retention, and compliance review is complete.';

create trigger quit_plans_set_updated_at
before update on public.quit_plans
for each row execute function public.set_updated_at();

alter table public.quit_plans enable row level security;
alter table public.quit_plans force row level security;

create policy "quit_plans_select_own"
on public.quit_plans for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "quit_plans_insert_own"
on public.quit_plans for insert
to authenticated
with check ((select auth.uid()) = user_id);

create policy "quit_plans_update_own"
on public.quit_plans for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on table public.quit_plans from anon, authenticated;
grant select on table public.quit_plans to authenticated;
grant insert (
  user_id, daily_cigarette_use, smoking_triggers, custom_smoking_trigger,
  readiness_path, quit_plan_path, quit_date, quit_day_check_in,
  quit_reasons, custom_quit_reason, top_quit_reason, support_people,
  preparation_tasks, treatment_support, care_team_reminder
) on table public.quit_plans to authenticated;
grant update (
  user_id, daily_cigarette_use, smoking_triggers, custom_smoking_trigger,
  readiness_path, quit_plan_path, quit_date, quit_day_check_in,
  quit_reasons, custom_quit_reason, top_quit_reason, support_people,
  preparation_tasks, treatment_support, care_team_reminder
) on table public.quit_plans to authenticated;

revoke all on function public.is_valid_support_people(jsonb)
from public, anon, authenticated;
revoke all on function public.is_unique_text_array(text[])
from public, anon, authenticated;

commit;
