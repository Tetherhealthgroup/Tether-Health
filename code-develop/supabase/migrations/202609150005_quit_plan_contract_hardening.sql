begin;

create or replace function public.is_valid_support_people(value jsonb)
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

create or replace function public.is_unique_text_array(value text[])
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

revoke all on function public.is_unique_text_array(text[])
from public, anon, authenticated;
grant execute on function public.is_unique_text_array(text[])
to authenticated;

alter table public.quit_plans
  drop constraint if exists quit_plans_smoking_triggers_check,
  add constraint quit_plans_smoking_triggers_check check (
    cardinality(smoking_triggers) <= 10 and
    public.is_unique_text_array(smoking_triggers) and
    smoking_triggers <@ array[
      'stress', 'afterMeals', 'driving', 'coffee', 'socialSettings',
      'workBreaks', 'alcohol', 'boredom', 'morning', 'beforeBed'
    ]::text[]
  ),
  drop constraint if exists quit_plans_quit_reasons_check,
  add constraint quit_plans_quit_reasons_check check (
    cardinality(quit_reasons) <= 7 and
    public.is_unique_text_array(quit_reasons) and
    quit_reasons <@ array[
      'family', 'breatheEasier', 'improveHealth', 'saveMoney',
      'control', 'future', 'custom'
    ]::text[]
  ),
  drop constraint if exists quit_plans_preparation_tasks_check,
  add constraint quit_plans_preparation_tasks_check check (
    cardinality(preparation_tasks) <= 3 and
    public.is_unique_text_array(preparation_tasks) and
    preparation_tasks <@ array[
      'removeSupplies', 'smokeFreeSpaces', 'stockAlternatives'
    ]::text[]
  );

commit;
