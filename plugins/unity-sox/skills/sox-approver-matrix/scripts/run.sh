#!/bin/zsh
# The whole quarterly control, one command.
#
#   ./run.sh
#
# EVERY run is a fresh run. Previous evidence is archived first and nothing is reused,
# because the menu-bar clock in each screenshot is the audit timestamp — mixing images
# from two runs would mean the evidence and the data describe different moments.
# There is deliberately no resume mode.
#
# Leave the machine idle while this runs (~10 min): it drives Chrome and takes
# full-screen screenshots. Every screenshot is OCR-verified before being kept, so an
# interrupted run produces no evidence rather than wrong evidence.
cd "${0:A:h}"
set -e
setopt NULL_GLOB

step() { echo; echo "===== $1 ====="; }

if ! ./preflight.sh; then
  echo
  echo "Preflight failed — fix the items above, then run ./run.sh again."
  exit 1
fi

# ---- always start clean -----------------------------------------------------
mkdir -p shots raw data
STAMP=$(date +%Y-%m-%d_%H%M)
OLD=(shots/*.png)
if (( ${#OLD} )); then
  mkdir -p "archive/$STAMP"
  mv shots/*.png "archive/$STAMP/"
  echo "Archived ${#OLD} previous screenshot(s) to archive/$STAMP/"
fi
rm -f raw/*.csv raw/*.json data/*.json report_totals.json timings.json
echo "Fresh run — no evidence from any previous run is reused."

step "1/4  Screenshots, report exports and permissions data"
./capture_all.sh

# Stop here rather than deep in a later step: an unverified screenshot is never
# written, so a missing file is the signal, and naming the missing ones is far more
# useful than a "missing screenshot: /long/path" further down the pipeline.
MISSING=$(./venv/bin/python - <<'PY'
import os, sys
sys.path.insert(0, ".")
from common import SHOTS, objects, permission_sets
want = ["cs_definition.png", "cs_rows.png"]
for o in objects():
    k = o["key"]
    want += [f"{k}_ipe_run.png", f"{k}_ipe_filters.png", f"{k}_modifyall.png"]
    try:
        want += [f"{k}_ps_{p}.png" for p in permission_sets(k)]
    except FileNotFoundError:
        pass
missing = [w for w in want if not os.path.exists(os.path.join(SHOTS, w))]
print("\n".join(missing))
PY
)
if [[ -n "$MISSING" ]]; then
  echo
  echo "STOPPING — these screenshots could not be verified and were not kept:"
  echo "$MISSING" | sed 's/^/  - /'
  echo
  echo "Nothing wrong was saved. Make sure the machine is completely idle"
  echo "(no keyboard, mouse or Chrome) and run ./run.sh again."
  exit 1
fi

step "2/4  Check evidence and data are from the same moment"
./venv/bin/python check_timing.py

step "3/4  Read counts off the screenshots and reconcile"
./venv/bin/python read_evidence.py
./venv/bin/python convert.py

step "4/4  Build and verify workbooks"
./venv/bin/python build.py
./venv/bin/python verify_out.py

OUTDIR="$(cd .. && pwd)/output"
echo
echo "================================================================"
echo "Done. Files are in:"
echo "  $OUTDIR"
echo "================================================================"
ls -la "$OUTDIR"/*.xlsx
echo
echo "Next: upload each file to Google Drive and open it with Google Sheets."
