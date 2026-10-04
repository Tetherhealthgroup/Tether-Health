#!/usr/bin/env bash
set -euo pipefail

migration="${1:-supabase/migrations/202610030001_avatar_deletion_barrier.sql}"

require() {
  if ! grep -Eiq "$1" "$migration"; then
    echo "Missing avatar-deletion barrier requirement: $2" >&2
    exit 1
  fi
}

require 'account_deletion_started_at timestamptz' 'durable deletion state'
require 'avatar_write_allowed\(object_name text\)' 'storage write predicate'
require 'for share' 'upload-side row lock that conflicts with marker updates'
if grep -Eiq 'for key share' "$migration"; then
  echo 'FOR KEY SHARE does not block a non-key deletion-marker update' >&2
  exit 1
fi
require 'update public\.profiles' 'deletion-side conflicting row lock'
require 'account_deletion_started_at = coalesce' 'idempotent deletion marker'
require 'storage\.foldername\(object_name\).*caller_id' 'caller prefix isolation'
require 'revoke all on function public\.avatar_write_allowed' 'write predicate default execute revoked'
require 'grant execute on function public\.avatar_write_allowed.*authenticated' 'authenticated write predicate grant'
require 'drop policy "avatars_insert_own"' 'insert policy replacement'
require 'drop policy "avatars_update_own"' 'update policy replacement'
require 'begin_account_deletion\(p_confirmation text\)' 'deletion barrier RPC'
require "p_confirmation is distinct from 'DELETE'" 'explicit confirmation'
require 'account_deletion_started_at is null' 'unstarted deletion rejection'
require 'revoke all on function public\.begin_account_deletion' 'default execute revoked'
require 'grant execute on function public\.begin_account_deletion.*authenticated' 'authenticated execute grant'

if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  echo 'Migration must not contain credentials or service-role use' >&2
  exit 1
fi

echo 'Avatar deletion barrier static policy checks passed.'
