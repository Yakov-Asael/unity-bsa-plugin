#!/usr/bin/env python
"""Turns the captured report CSVs and permissions JSON into build.py's inputs."""
import csv, json, os, sys
from common import RAW, DATA, ROOT, objects, permission_sets, load_json

os.makedirs(DATA, exist_ok=True)

OBJPERM_Q = ("SELECT id,Parent.Profile.Name, Parent.Name, Parent.PermissionsTransferAnyLead, "
             "PermissionsCreate, PermissionsDelete, PermissionsEdit, "
             "PermissionsModifyAllRecords, SobjectType\nFROM ObjectPermissions\n\n"
             "where SobjectType in ('{s}')\nand PermissionsModifyAllRecords = true")
PSA_Q = ("select id,Assignee.Name,Assignee.Profile.Name,Assignee.FN_Role__c "
         "from PermissionSetAssignment\nwhere PermissionSet.Name = '{p}' AND IsActive = true")

# Read off the IPE screenshots by read_evidence.py. Kept separate from the CSV row
# count on purpose: the IPE tab reconciles the two, so deriving one from the other
# would make the control check meaningless.
with open(os.path.join(os.path.dirname(RAW), "report_totals.json")) as fh:
    REPORT_TOTALS = json.load(fh)

problems = []

for obj in objects():
    key = obj["key"]
    with open(os.path.join(RAW, f"{key}.csv"), newline="", encoding="utf-8-sig") as fh:
        rows = list(csv.reader(fh))

    # Salesforce appends footer lines (grand totals, a confidentiality notice, a
    # generated-on stamp) after the data; keep only rows matching the header width.
    header, body = rows[0], rows[1:]
    data = [r for r in body if len(r) == len(header) and any(c.strip() for c in r)]

    total = REPORT_TOTALS[key]
    if len(data) != total:
        problems.append(f"{key}: CSV has {len(data)} rows, report screenshot says {total}")

    op = load_json(os.path.join(RAW, f"{key}_objperm.json"))
    op_rows = [[r.get("Parent.Name", ""), r.get("Parent.Profile.Name", ""),
                r.get("SobjectType", ""), r.get("PermissionsModifyAllRecords", "")]
               for r in op.get("rows", [])]

    psets = []
    for ps in permission_sets(key):
        p = load_json(os.path.join(RAW, f"{key}_psa_{ps}.json"))
        psets.append({
            "name": ps,
            "query": PSA_Q.format(p=ps),
            "assignments": [[r.get("Assignee.Name", ""), r.get("Assignee.Profile.Name", ""),
                             r.get("Assignee.FN_Role__c", "")] for r in p.get("rows", [])],
        })

    out = {
        "display": obj["display"],
        "sobject": obj["sobject"],
        "approvers": obj.get("approvers", []),
        "columns": header,
        "rows": data,
        "total_records": total,
        "objperm_query": OBJPERM_Q.format(s=obj["sobject"]),
        "objperm_rows": op_rows,
        "permission_sets": psets,
    }
    with open(os.path.join(DATA, f"{key}.json"), "w") as fh:
        json.dump(out, fh, indent=1)

    print(f"{key:8s} rows={len(data):5d} (report {total:5d})  cols={len(header)}  "
          f"objperm={len(op_rows)}  "
          f"psets={[(p['name'][:26], len(p['assignments'])) for p in psets]}")

if problems:
    print("\nPROBLEMS:")
    for p in problems:
        print(" -", p)
    sys.exit(1)
