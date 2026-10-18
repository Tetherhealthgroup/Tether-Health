#!/bin/bash
# Rebuild everything from the spec and validate it end to end.
# Needs: python3, playwright (pip install playwright && playwright install chromium), Flutter 3.22+.
set -e
cd "$(dirname "$0")"
python3 build_all.py --images
mkdir -p ../validation
(cd ../flutter && flutter pub get >/dev/null && flutter analyze > ../validation/analyze.txt 2>&1; flutter test --reporter json > /tmp/tether_flutter.json || true)
python3 check_prototype.py ../validation/prototype_results.json
python3 report.py /tmp/tether_flutter.json ../validation/prototype_results.json
python3 build_all.py   # refresh README numbers
echo "Report: ../validation/report.md"
