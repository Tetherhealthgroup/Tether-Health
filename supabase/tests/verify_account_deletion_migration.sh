#!/usr/bin/env bash
set -euo pipefail

migration="${1:-supabase/migrations/202609200001_account_data_deletion.sql}"

require() {
  if ! grep -Eiq "$1" "$migration"; then
    echo "Missing account-deletion migration requirement: $2" >&2
    exit 1
  fi
}

require 'security definer' 'controlled privileged function'
require "auth\.uid\(\)" 'caller identity from JWT'
require "p_confirmation.*DELETE" 'explicit confirmation'
require 'delete from public\.quit_plans where user_id = caller_id' 'caller plan deletion'
require 'delete from public\.profiles where id = caller_id' 'caller profile deletion'
require 'revoke all on function public\.delete_my_app_data' 'default execute revoked'
require 'grant execute.*authenticated' 'authenticated execution grant'
require 'Auth identity deletion remains a separate privileged operation' 'Auth boundary documentation'

if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  echo 'Migration must not contain credentials or service-role use' >&2
  exit 1
fi

echo 'Account deletion migration static policy checks passed.'
