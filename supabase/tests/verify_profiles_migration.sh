#!/usr/bin/env bash
set -euo pipefail

migration="$(cd "$(dirname "$0")/.." && pwd)/migrations/202609110001_profiles.sql"

require_pattern() {
  if ! grep -Eiq "$1" "$migration"; then
    echo "Missing required migration contract: $2" >&2
    exit 1
  fi
}

require_pattern 'id uuid primary key references auth\.users\(id\) on delete cascade' 'auth-linked primary key'
require_pattern 'alter table public\.profiles enable row level security' 'RLS enabled'
require_pattern 'alter table public\.profiles force row level security' 'RLS forced'
require_pattern 'auth\.uid\(\).* = id' 'caller-scoped profile policy'
require_pattern 'revoke all on table public\.profiles from anon, authenticated' 'default grants revoked'
require_pattern 'grant update \(display_name, locale, time_zone, onboarding_completed, avatar_path\)' 'column-scoped update grant'
require_pattern 'select id from auth\.users' 'existing auth user backfill'
require_pattern "values \('avatars', 'avatars', false" 'private avatars bucket'
require_pattern 'storage\.foldername\(name\).*auth\.uid\(\)' 'caller-scoped avatar policy'

if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  echo 'Migration must not contain credentials or service-role use' >&2
  exit 1
fi

echo 'Profile migration static policy checks passed.'
