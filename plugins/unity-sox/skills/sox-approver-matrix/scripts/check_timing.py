#!/usr/bin/env python
"""
Enforces that each report's screenshot and its CSV export describe the same moment.

The IPE screenshot is the evidence that the population in Results is what the report
actually showed. If the two were taken far apart the report could have changed in
between, and the evidence would no longer support the data. Failing the run is better
than shipping a workbook whose evidence and data disagree.
"""
import datetime, os, sys
from common import HERE, RAW, config, keys, load_json

cfg = config()
MAX_GAP = cfg["limits"]["max_screenshot_export_gap_seconds"]
timings = load_json(os.path.join(HERE, "timings.json"))

missing = [k for k in keys() if k not in timings]
if missing:
    sys.exit(f"timings.json is missing: {', '.join(missing)} — the run did not complete")


def ts(epoch):
    return datetime.datetime.fromtimestamp(epoch).strftime("%H:%M:%S")


print(f"Screenshot / export pairing (limit {MAX_GAP}s)")
bad = []
for k in keys():
    t = timings[k]
    gap = t["csv"] - t["shot"]
    ok = 0 <= gap <= MAX_GAP
    if not ok:
        bad.append(f"{k}: {gap}s between screenshot and CSV export")
    print(f"  {k:8s} shot {ts(t['shot'])}  csv {ts(t['csv'])}  gap {gap:>4}s  "
          f"{'OK' if ok else 'TOO FAR APART'}")

# The CSV on disk must be the one this run produced, not a leftover from last quarter.
for k in keys():
    p = os.path.join(RAW, f"{k}.csv")
    if not os.path.exists(p):
        bad.append(f"{k}: raw/{k}.csv is missing")
        continue
    drift = abs(os.path.getmtime(p) - timings[k]["csv"])
    if drift > 120:
        bad.append(f"{k}: raw/{k}.csv is {int(drift)}s from this run's export — stale file")

if bad:
    print("\nTIMING CHECK FAILED:")
    for b in bad:
        print("  -", b)
    sys.exit(1)
print("\nEvidence and data are from the same moment.")
