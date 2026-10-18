begin;

-- Align quit-plan option checks with the current BreatheFree onboarding
-- options. Additive only: every value accepted before this migration is still
-- accepted, so existing rows remain valid. RLS, policies and grants on
-- public.quit_plans are not changed.
--
-- * smoking_triggers gains 'scrolling'. 'beforeBed' is no longer offered by the
--   UI but stays valid for existing rows. The size bound grows to 11 so that
--   any unique subset of the allowed values is still accepted.
-- * quit_plan_path gains 'exploreFirst'. A plan on that path must also record
--   readiness_path = 'explore', so the two columns cannot disagree.

alter table public.quit_plans
  drop constraint if exists quit_plans_smoking_triggers_check,
  add constraint quit_plans_smoking_triggers_check check (
    cardinality(smoking_triggers) <= 11 and
    public.is_unique_text_array(smoking_triggers) and
    smoking_triggers <@ array[
      'stress', 'afterMeals', 'driving', 'coffee', 'socialSettings',
      'workBreaks', 'alcohol', 'boredom', 'morning', 'beforeBed',
      'scrolling'
    ]::text[]
  ),
  drop constraint if exists quit_plans_quit_plan_path_check,
  add constraint quit_plans_quit_plan_path_check check (
    quit_plan_path in (
      'setQuitDate', 'quitToday', 'reduceGradually', 'exploreFirst'
    )
  ),
  drop constraint if exists quit_plans_explore_first_readiness_check,
  add constraint quit_plans_explore_first_readiness_check check (
    quit_plan_path <> 'exploreFirst' or readiness_path = 'explore'
  );

comment on column public.quit_plans.smoking_triggers is
  'Trigger identifiers. ''beforeBed'' is a legacy value kept valid for existing rows; current onboarding offers ''scrolling'' instead.';

comment on column public.quit_plans.quit_plan_path is
  'Chosen quit path. ''exploreFirst'' requires readiness_path = ''explore''.';

commit;
