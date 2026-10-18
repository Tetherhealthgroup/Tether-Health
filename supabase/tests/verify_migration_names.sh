#!/usr/bin/env bash
# Checks every file in supabase/migrations:
#   * the name is YYYYMMDDNNNN_name.sql: a 12-digit version (a real month and
#     day, sequence 0001-9999), then lowercase letters, digits and underscores;
#   * versions are unique and strictly increasing in filename order, so the
#     order the Supabase CLI applies them in is the order they were written;
#   * nothing else is in the directory (no 14-digit timestamps, no other files).
#
#   bash supabase/tests/verify_migration_names.sh
set -euo pipefail

migrations_dir="$(cd "$(dirname "$0")/.." && pwd)/migrations"

fail() {
  echo "Migration name check failed: $1" >&2
  exit 1
}

name_pattern='^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{4})_[a-z0-9_]+\.sql$'

# Prints nothing and returns 0 when the names (one per argument, in the order
# given) are valid; otherwise prints the first problem and returns 1.
check_names() {
  local previous='' name month day seq version
  [[ $# -gt 0 ]] || { echo 'no migrations found'; return 1; }
  for name in "$@"; do
    if [[ ! "$name" =~ $name_pattern ]]; then
      echo "$name: not YYYYMMDDNNNN_name.sql (12-digit version, lowercase name)"
      return 1
    fi
    month=$((10#${BASH_REMATCH[2]}))
    day=$((10#${BASH_REMATCH[3]}))
    seq=$((10#${BASH_REMATCH[4]}))
    if ((month < 1 || month > 12 || day < 1 || day > 31 || seq < 1)); then
      echo "$name: version is not a valid YYYYMMDD date with sequence 0001-9999"
      return 1
    fi
    version="${name:0:12}"
    if [[ -n "$previous" && ! "$version" > "$previous" ]]; then
      echo "$name: version $version is not greater than the previous $previous"
      return 1
    fi
    previous="$version"
  done
}

# Self-test of the checker; runs every time.
check_names 202609110001_profiles.sql 202610170002_enrolments.sql \
  202610180001_sync_tables.sql >/dev/null ||
  fail 'checker rejects valid names'
for bad in \
  '20260915094500_create_sync_tables.sql' \
  '2026091100001_profiles.sql' \
  '20260911001_profiles.sql' \
  '202609110001-profiles.sql' \
  '202609110001_Profiles.sql' \
  '202609110001_profiles.SQL' \
  '202609110001_.sql' \
  '202609110001_profiles.sql.bak' \
  '202613010001_bad_month.sql' \
  '202609000001_bad_day.sql' \
  '202609320001_bad_day.sql' \
  '202609110000_zero_sequence.sql' \
  'README.md'; do
  if check_names "$bad" >/dev/null; then fail "checker accepts '$bad'"; fi
done
if check_names 202609110001_a.sql 202609110001_b.sql >/dev/null; then
  fail 'checker accepts a duplicate version'
fi
if check_names 202609110002_a.sql 202609110001_b.sql >/dev/null; then
  fail 'checker accepts a decreasing version'
fi

[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

names=()
while IFS= read -r -d '' path; do
  names+=("${path##*/}")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -print0 | LC_ALL=C sort -z)

[[ ${#names[@]} -gt 0 ]] || fail "no migrations in $migrations_dir"
problem=$(check_names "${names[@]}") || fail "$problem"

echo "Migration name checks passed (${#names[@]} migrations)."
