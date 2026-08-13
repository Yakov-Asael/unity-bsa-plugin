#!/usr/bin/env python
"""
Reads the record counts straight off the evidence screenshots using Apple's Vision
OCR, writes report_totals.json, and reconciles every screenshot against the data.

The numbers come from the *images* rather than from the data on purpose. If a report
and its export ever disagree, that is exactly what the control is meant to catch, so
deriving one from the other would defeat it.
"""
import json, os, re, subprocess, sys
from common import HERE, SHOTS, RAW, objects, permission_sets, load_json

OCR = os.path.join(HERE, "ocr")


def ocr(path, box=()):
    if not os.path.exists(path):
        raise SystemExit(f"missing screenshot: {path}")
    if not os.path.exists(OCR):
        raise SystemExit("ocr binary not built — run: swiftc -O -o ocr ocr.swift")
    out = subprocess.run([OCR, path, *box], capture_output=True, text=True)
    if out.returncode != 0:
        raise SystemExit(f"OCR failed on {path}: {out.stderr.strip()}")
    return out.stdout.splitlines()


# OCR is not character-perfect on UI chrome — "Total Records" has come back as
# "Totel Records". Match the label loosely, then take the first standalone number
# after it. Salesforce record ids never match [\d,]+.
LABEL_TOTAL = re.compile(r"t[o0]t[a-z]l\s+rec[o0]rds?", re.I)
BOX_TOTAL = ("0.00", "0.18", "0.45", "0.55")
BOX_EXPORT = ("0.50", "0.28", "0.50", "0.45")


def total_records(key):
    lines = ocr(os.path.join(SHOTS, f"{key}_ipe_run.png"), BOX_TOTAL)
    for i, ln in enumerate(lines):
        if LABEL_TOTAL.search(ln):
            for nxt in lines[i + 1:]:
                if re.fullmatch(r"[\d,]+", nxt.strip()):
                    return int(nxt.strip().replace(",", ""))
    raise SystemExit(f"{key}: could not read 'Total Records'.\nOCR saw: {lines}")


def exported_count(shot):
    for ln in ocr(os.path.join(SHOTS, shot), BOX_EXPORT):
        m = re.search(r"Exported\s+([\d,]+)\s+record", ln, re.I)
        if m:
            return int(m.group(1).replace(",", ""))
    raise SystemExit(f"could not read 'Exported N records' from {shot}")


def main():
    objs = objects()
    bad = []

    totals = {}
    print("Report screenshots — Total Records")
    for o in objs:
        totals[o["key"]] = total_records(o["key"])
        print(f"  {o['key']:8s} {totals[o['key']]:>7,}")
    with open(os.path.join(os.path.dirname(RAW), "report_totals.json"), "w") as fh:
        json.dump(totals, fh, indent=1)

    print("\nInspector screenshots — Exported N records vs extracted data")
    for o in objs:
        key = o["key"]
        want = len(load_json(os.path.join(RAW, f"{key}_objperm.json")).get("rows", []))
        got = exported_count(f"{key}_modifyall.png")
        if got != want:
            bad.append(f"{key}_modifyall: screenshot {got}, data {want}")
        print(f"  {key + '_modifyall':30s} shot={got:>4}  data={want:>4}  "
              f"{'OK' if got == want else 'MISMATCH'}")

        for ps in permission_sets(key):
            want = len(load_json(os.path.join(RAW, f"{key}_psa_{ps}.json")).get("rows", []))
            got = exported_count(f"{key}_ps_{ps}.png")
            if got != want:
                bad.append(f"{key}_ps_{ps}: screenshot {got}, data {want}")
            print(f"  {(key + '_ps_' + ps)[:30]:30s} shot={got:>4}  data={want:>4}  "
                  f"{'OK' if got == want else 'MISMATCH'}")

    # OCR the whole image for these: the filter rows sit at different heights
    # depending on how many filters a report has, and a fixed crop silently cut off
    # the "Show Me" row. "Show Me" only appears in the Filters panel, so there is
    # nothing to disambiguate by cropping.
    print("\nFilters screenshots")
    for o in objs:
        text = "\n".join(ocr(os.path.join(SHOTS, f"{o['key']}_ipe_filters.png"))).lower()
        if not ("show me" in text or "add filter" in text):
            bad.append(f"{o['key']}_ipe_filters: shows the Outline panel, not Filters")
            print(f"  {o['key']:8s} NOT THE FILTERS PANEL")
        elif o["report_name"].lower() not in text:
            bad.append(f"{o['key']}_ipe_filters: not the {o['report_name']} report")
            print(f"  {o['key']:8s} WRONG REPORT")
        else:
            print(f"  {o['key']:8s} OK — Filters panel, {o['report_name']}")

    # A wrong identifier renders "Invalid Custom Setting id" on an otherwise normal
    # Setup page, which would pass unnoticed as evidence.
    from common import config
    label = config()["custom_setting"]["label"]
    print("\nCustom Settings screenshots")
    for shot in ("cs_definition.png", "cs_rows.png"):
        text = "\n".join(ocr(os.path.join(SHOTS, shot))).lower()
        if "invalid" in text or "error" in text:
            bad.append(f"{shot}: page shows an error, not the custom setting")
            print(f"  {shot:22s} ERROR PAGE")
        elif label.lower() not in text:
            bad.append(f"{shot}: '{label}' not found on the page")
            print(f"  {shot:22s} MISSING '{label}'")
        else:
            print(f"  {shot:22s} OK — shows '{label}'")

    if bad:
        print("\nEVIDENCE MISMATCH:")
        for b in bad:
            print("  -", b)
        sys.exit(1)
    print("\nAll evidence reconciles.")


if __name__ == "__main__":
    main()
