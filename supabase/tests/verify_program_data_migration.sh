#!/usr/bin/env bash
set -euo pipefail

migration="${1:-supabase/migrations/202609260001_program_data.sql}"
require() {
  if ! grep -Eiq "$1" "$migration"; then
    echo "Missing program-data migration requirement: $2" >&2
    exit 1
  fi
}
require 'enable row level security' 'RLS enabled'
require 'force row level security' 'RLS forced'
require "program_id in .*heartwise.*steady.*clearair" 'bounded program ids'
require 'octet_length\(payload::text\).*32768' 'bounded payload'
require 'auth\.uid\(\).*user_id' 'caller-scoped policies'
require 'delete from public\.program_data where user_id = caller_id' 'deletion integration'
require 'create function public\.save_program_data' 'atomic save function'
require 'p_revision <> current_revision \+ 1' 'strict sequential revision guard'
require 'pg_advisory_xact_lock' 'per-caller/program write serialization'
if grep -Eiq 'service[_-]?role|secret|password[[:space:]]*=' "$migration"; then
  echo 'Migration must not contain credentials or service-role use' >&2
  exit 1
fi
echo 'Program data migration static policy checks passed.'
