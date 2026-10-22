begin;

-- public.wellbeing_baseline.age_range holds one of a fixed list of age bands:
-- 18_24, 25_34, 35_44, 45_54, 55_64, 65_74 or 75_plus (everyone 75 and over
-- is one band). It stays nullable. The constraint keeps its name; adding it
-- checks the rows already stored, so a stored value outside the list stops
-- this migration. No other table, grant, policy, trigger or function changes.

alter table public.wellbeing_baseline drop constraint wellbeing_baseline_age_range_check;
alter table public.wellbeing_baseline add constraint wellbeing_baseline_age_range_check check (age_range in ('18_24', '25_34', '35_44', '45_54', '55_64', '65_74', '75_plus'));

commit;
