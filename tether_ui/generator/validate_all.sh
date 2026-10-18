#!/bin/bash
# Rebuild everything from the spec and validate it end to end.
# Needs: python3, playwright (pip install playwright && playwright install chromium), Flutter 3.22+.
# Exits non-zero if the spec validator, flutter analyze, any Flutter test, or
# any prototype scenario / sweep case fails. The report is still written first.
set -euo pipefail
cd "$(dirname "$0")"
python3 build_all.py --images
mkdir -p ../validation
results="$(mktemp)"
trap 'rm -f "$results"' EXIT
status=0
(cd ../flutter && flutter pub get >/dev/null)
(cd ../flutter && flutter analyze) > ../validation/analyze.txt 2>&1 || { echo "FAIL: flutter analyze (see validation/analyze.txt)"; status=1; }
(cd ../flutter && flutter test --reporter json) > "$results" || { echo "FAIL: flutter test"; status=1; }
python3 check_prototype.py ../validation/prototype_results.json
python3 report.py "$results" ../validation/prototype_results.json
python3 build_all.py   # refresh README numbers
python3 - ../validation/summary.json <<'PY' || status=1
import json, sys
s = json.load(open(sys.argv[1]))
f, p = s['flutter'], s['prototype']
bad = []
if f['total'] == 0 or f['passed'] != f['total']: bad.append(f"flutter tests {f['passed']}/{f['total']}")
for k in ('scenarios', 'action_sweep'):
    ok, n = p[k]
    if n == 0 or ok != n: bad.append(f'prototype {k} {ok}/{n}')
if p['js_errors']: bad.append(f"prototype js errors {p['js_errors']}")
for b in bad: print('FAIL:', b)
sys.exit(1 if bad else 0)
PY
echo "Report: ../validation/report.md"
exit "$status"
