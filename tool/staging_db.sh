#!/bin/sh
# Runs the owner's database steps against the STAGING Supabase project only
# (docs/STAGING.md). Refuses before running anything unless the target is a
# staging host. Synthetic data only.
#
# Usage: sh tool/staging_db.sh check
#        sh tool/staging_db.sh migrate [--dry-run]
#        sh tool/staging_db.sh list
#        sh tool/staging_db.sh seed [--dry-run]
#
# check     Only check the target (below), then exit.
# migrate   supabase db push: applies every file in supabase/migrations not yet
#           applied, in filename order, and records it. With --dry-run,
#           supabase prints what it would apply and applies nothing.
# list      supabase migration list: which migrations are applied (read-only).
# seed      Runs supabase/staging/seed_staging.sql with supabase db query.
#           With --dry-run, checks everything and runs nothing.
#
# The target is the connection string in the environment variable
# STAGING_DATABASE_URL (postgresql://postgres:<password>@<host>:5432/postgres,
# percent-encoded). It is never taken from an argument and never printed. Its
# host must belong to a host in STAGING_HOSTS (tool/release_define_check.sh):
#   db.<ref>.supabase.co                   -> <ref>.supabase.co must be listed
#   <region>.pooler.supabase.com, user
#   postgres.<ref>                         -> <ref>.supabase.co must be listed
#   any other host                         -> that host must be listed
# STAGING_HOSTS is empty until the owner creates staging, so every command is
# refused until then.
#
# The Supabase CLI receives the connection string as its --db-url argument
# (the CLI has no other way to take it without linking the project), so it is
# visible to other processes of the same user while the command runs.
#
# Exit codes: 0 success, 1 a check failed or the CLI failed, 2 usage error.
set -eu
unset CDPATH

fail() {
  echo "staging_db: $1" >&2
  exit "${2:-1}"
}

[ "$#" -ge 1 ] || fail "a command is required: check, migrate, list or seed" 2
command="$1"
shift
dry_run=0
case "$command" in
  check | list)
    [ "$#" -eq 0 ] || fail "$command takes no options" 2
    ;;
  migrate | seed)
    if [ "$#" -eq 1 ] && [ "$1" = "--dry-run" ]; then
      dry_run=1
    elif [ "$#" -ne 0 ]; then
      fail "$command accepts only --dry-run" 2
    fi
    ;;
  *) fail "unknown command (not shown); use check, migrate, list or seed" 2 ;;
esac

[ -n "${STAGING_DATABASE_URL:-}" ] || fail "STAGING_DATABASE_URL is not set"

cd "$(dirname "$0")/.."

# The project host the connection belongs to (not secret); nothing on error.
project_host="$(python3 -I - <<'PY'
import os, sys
from urllib.parse import unquote, urlsplit

try:
    url = urlsplit(os.environ["STAGING_DATABASE_URL"].strip())
    host = (url.hostname or "").lower().rstrip(".")
    user = unquote(url.username or "")
except Exception:
    sys.exit(1)
if url.scheme not in ("postgresql", "postgres") or not host:
    sys.exit(1)
if host.startswith("db.") and host.endswith(".supabase.co"):
    host = host[3:]
elif host.endswith(".pooler.supabase.com"):
    if not user.startswith("postgres.") or len(user) == len("postgres."):
        sys.exit(1)
    host = user[len("postgres."):].lower() + ".supabase.co"
print(host)
PY
)" || fail "STAGING_DATABASE_URL is not a postgresql:// URL with a host (value not shown)"

# shellcheck source=tool/release_define_check.sh
. tool/release_define_check.sh
is_staging_host staging_db "$project_host" || exit 1
echo "staging_db: the target belongs to a host in STAGING_HOSTS."

if [ "$command" = check ]; then
  exit 0
fi
command -v supabase >/dev/null 2>&1 || fail "the Supabase CLI (supabase) is not on PATH"

case "$command" in
  migrate)
    if [ "$dry_run" -eq 1 ]; then
      echo "== supabase db push --dry-run (nothing is applied)"
      supabase db push --db-url "$STAGING_DATABASE_URL" --dry-run
    else
      echo "== supabase db push"
      supabase db push --db-url "$STAGING_DATABASE_URL"
    fi
    ;;
  list)
    echo "== supabase migration list"
    supabase migration list --db-url "$STAGING_DATABASE_URL"
    ;;
  seed)
    [ -f supabase/staging/seed_staging.sql ] || fail "supabase/staging/seed_staging.sql not found"
    if [ "$dry_run" -eq 1 ]; then
      echo "Dry run: would run supabase/staging/seed_staging.sql with supabase db query; nothing was run."
    else
      echo "== supabase db query -f supabase/staging/seed_staging.sql"
      supabase db query --db-url "$STAGING_DATABASE_URL" -f supabase/staging/seed_staging.sql
    fi
    ;;
esac
