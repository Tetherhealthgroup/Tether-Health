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

alter table public.quit_plans
  drop constraint if exists quit_plans_custom_reason_selection_check,
  add constraint quit_plans_custom_reason_selection_check check (
    ('custom' = any(quit_reasons)) = (custom_quit_reason is not null)
  );

commit;
