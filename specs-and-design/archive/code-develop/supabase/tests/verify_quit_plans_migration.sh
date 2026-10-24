#!/usr/bin/env bash
set -euo pipefail

migration="${1:-supabase/migrations/202609150001_quit_plans.sql}"
grants_migration="${2:-supabase/migrations/202609150002_quit_plan_validator_grant.sql}"
upsert_grant_migration="${3:-supabase/migrations/202609150003_quit_plan_upsert_grant.sql}"
integrity_migration="${4:-supabase/migrations/202609150004_quit_plan_integrity.sql}"
hardening_migration="${5:-supabase/migrations/202609150005_quit_plan_contract_hardening.sql}"

require() {
  local pattern="$1"
  local message="$2"
  if ! grep -Eiq "$pattern" "$migration"; then
    echo "Missing migration requirement: $message" >&2
    exit 1
  fi
}

require 'create table public\.quit_plans' 'quit_plans table'
require 'references public\.profiles\(id\) on delete cascade' 'profile-owned cascading identity'
require 'enable row level security' 'RLS enabled'
require 'force row level security' 'RLS forced'
require 'quit_plans_select_own' 'owner-only SELECT policy'
require 'quit_plans_insert_own' 'owner-only INSERT policy'
require 'quit_plans_update_own' 'owner-only UPDATE policy'
require 'auth\.uid\(\).*user_id' 'caller identity predicate'
require 'is_valid_support_people' 'bounded support-person validation'
require 'revoke all on table public\.quit_plans from anon, authenticated' 'default table privileges revoked'
require 'grant select on table public\.quit_plans to authenticated' 'authenticated SELECT grant'
require 'grant insert' 'authenticated INSERT grant'
require 'grant update' 'authenticated UPDATE grant'
require 'Development-only quit-plan snapshot' 'synthetic-data-only boundary comment'

if ! grep -Eiq 'grant execute on function public\.is_valid_support_people\(jsonb\)' "$grants_migration"; then
  echo 'Missing migration requirement: authenticated validator execution grant' >&2
  exit 1
fi
if ! grep -Eiq 'grant update \(user_id\) on table public\.quit_plans' "$upsert_grant_migration"; then
  echo 'Missing migration requirement: authenticated upsert conflict-column grant' >&2
  exit 1
fi
if ! grep -Eiq 'count\(distinct entry.*id' "$integrity_migration"; then
  echo 'Missing migration requirement: unique support-person ids' >&2
  exit 1
fi
if ! grep -Eiq 'custom_reason_selection_check' "$integrity_migration"; then
  echo 'Missing migration requirement: custom reason selection consistency' >&2
  exit 1
fi
if ! grep -Eiq "entry - array\['id'.*'enabled'\].*<>.*jsonb" "$hardening_migration"; then
  echo 'Missing migration requirement: exact support-person object keys' >&2
  exit 1
fi
if ! grep -Eiq 'is_unique_text_array' "$hardening_migration"; then
  echo 'Missing migration requirement: unique enum arrays' >&2
  exit 1
fi

echo 'Quit-plan migration static policy checks passed.'
