#!/bin/zsh
# Captures every screenshot, exports every report, and extracts the permissions data
# for the quarterly SOX approver-matrix control. Driven entirely by ../config.json.
#
# Two design points worth knowing:
#
# 1. A report's screenshot and that report's CSV export happen BACK TO BACK. The
#    screenshot is the evidence that the rows in Results are what the report actually
#    showed; if they were taken far apart the report could have changed in between.
#
# 2. Permission sets are DISCOVERED, not configured. The ObjectPermissions result is
#    read out of the page, and every row without a profile is a real permission set
#    that then gets its own assignment query. So granting Modify All to a new
#    permission set needs no change here — it shows up on the next run by itself.
cd "${0:A:h}"
set +e
setopt NULL_GLOB
mkdir -p shots raw

PY=./venv/bin/python
CFG=../config.json
DL="$HOME/Downloads"
TIMINGS=timings.json

[[ -x ./ocr ]] || swiftc -O -o ocr ocr.swift || { echo "cannot build ocr"; exit 1; }

cfg() { $PY -c "import json,sys; d=json.load(open('$CFG')); print(eval(sys.argv[1],{'d':d}))" "$1"; }

LEXHOST=$(cfg "d['org']['lightning_host']")
MYHOST=$(cfg "d['org']['my_host']")
SETUPHOST=$(cfg "d['org']['setup_host']")
EXTID=$(cfg "d['org']['inspector_extension_id']")
CS_OBJ=$(cfg "d['custom_setting']['object_id']")
CS_PREFIX=$(cfg "d['custom_setting']['key_prefix']")
CS_LABEL=$(cfg "d['custom_setting']['label']")

INSP="chrome-extension://$EXTID/data-export.html?host=$MYHOST"
LEX="https://$LEXHOST/lightning/r/Report"
CS="https://$SETUPHOST/lightning/setup/CustomSettings/page?address="

enc() { $PY -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"; }

page_shot()    { ./shot.sh "$1" "$2" "$3" "${4:-16}"; }
# The report builder opens on Outline; open the Filters tab before capturing.
# "Show Me" is a small grey label that OCR merges into the line below it on the
# denser reports; "Add filter..." is the same panel's search box and reads cleanly.
filters_shot() { ./shot.sh "$1" "$2" "Add filter|Show Me" 18 0 open_filters.js; }
insp_shot()    { ./shot.sh "$INSP&query=$(enc "$1")" "$2" "Export Result" 10 1; }

# Pull the Inspector's result table out of the page as JSON, so the workbook data and
# the screenshot come from the same query run rather than from a separate API call.
extract_to() { ./chrome_js.sh extract_results.js > "$1"; }

objperm_q() {
  printf '%s\n%s\n\n%s\n%s' \
    "SELECT id,Parent.Profile.Name, Parent.Name, Parent.PermissionsTransferAnyLead, PermissionsCreate, PermissionsDelete, PermissionsEdit, PermissionsModifyAllRecords, SobjectType" \
    "FROM ObjectPermissions" "where SobjectType in ('$1')" "and PermissionsModifyAllRecords = true"
}
psa_q() {
  printf '%s\n%s' \
    "select id,Assignee.Name,Assignee.Profile.Name,Assignee.FN_Role__c from PermissionSetAssignment" \
    "where PermissionSet.Name = '$1' AND IsActive = true"
}

export_csv() {  # export_csv <key> <reportId> -- runs immediately after its screenshot
  local key="$1" rid="$2" before after i s1 s2 WID
  WID=$(cat .capture_window 2>/dev/null)
  before=$(ls -t "$DL"/*.csv(N) 2>/dev/null | head -1)
  osascript >/dev/null 2>&1 <<EOF
tell application "Google Chrome"
  set URL of active tab of (window id $WID) to "https://$MYHOST/$rid?export=1&enc=UTF-8&xf=csv&isdtp=nv"
end tell
EOF
  for i in {1..20}; do
    sleep 2
    after=$(ls -t "$DL"/*.csv(N) 2>/dev/null | head -1)
    [[ "$after" != "$before" && -s "$after" ]] && break
  done
  [[ "$after" == "$before" ]] && { echo "   ABORT: no CSV appeared for $key"; return 1; }
  s1=$(wc -c < "$after"); sleep 2; s2=$(wc -c < "$after")
  [[ "$s1" != "$s2" ]] && sleep 3
  mv "$after" "raw/$key.csv"
  echo "   csv  $key -> $(( $(wc -l < "raw/$key.csv") - 1 )) data rows"
}

# --- Custom Settings evidence (identical for every object, captured once) ---
page_shot "${CS}%2Fsetup%2Fui%2FviewCustomSettings.apexp%3Fid%3D${CS_OBJ}" \
          shots/cs_definition.png "$CS_LABEL" 14
page_shot "${CS}%2Fsetup%2Fui%2FlistCustomSettingsData.apexp%3Fid%3D${CS_PREFIX}" \
          shots/cs_rows.png "$CS_LABEL" 14

NOBJ=$(cfg "len(d['objects'])")
echo "{" > "$TIMINGS"
FIRST=1

for ((n=0; n<NOBJ; n++)); do
  key=$(cfg "d['objects'][$n]['key']")
  rid=$(cfg "d['objects'][$n]['report_id']")
  sobj=$(cfg "d['objects'][$n]['sobject']")
  rname=$(cfg "d['objects'][$n]['report_name']")

  echo "=== $key ($sobj) ==="

  # ---- paired step: the run report, then its CSV, back to back ----
  page_shot "$LEX/$rid/view?queryScope=userFolders" "shots/${key}_ipe_run.png" "$rname" 16 || continue
  T_SHOT=$(date +%s)
  export_csv "$key" "$rid" || continue
  T_CSV=$(date +%s)
  echo "   gap  $(( T_CSV - T_SHOT ))s between screenshot and export"

  [[ "$FIRST" == "1" ]] && FIRST=0 || echo "," >> "$TIMINGS"
  printf '  "%s": {"shot": %s, "csv": %s}' "$key" "$T_SHOT" "$T_CSV" >> "$TIMINGS"

  filters_shot "$LEX/$rid/edit?queryScope=userFolders" "shots/${key}_ipe_filters.png"

  # ---- Modify All: screenshot, then read the same result table out of the page ----
  insp_shot "$(objperm_q "$sobj")" "shots/${key}_modifyall.png" || continue
  extract_to "raw/${key}_objperm.json"

  # Rows with no profile are real permission sets; each needs its own evidence.
  PSETS=$($PY -c "
import json
d=json.load(open('raw/${key}_objperm.json'))
names=[r.get('Parent.Name','') for r in d.get('rows',[]) if not r.get('Parent.Profile.Name')]
print(' '.join(sorted(set(n for n in names if n))))
" 2>/dev/null)
  echo "   permission sets: ${PSETS:-none}"

  for ps in ${=PSETS}; do
    insp_shot "$(psa_q "$ps")" "shots/${key}_ps_${ps}.png" || continue
    extract_to "raw/${key}_psa_${ps}.json"
  done
done
echo "" >> "$TIMINGS"; echo "}" >> "$TIMINGS"

echo "=== DONE ==="
echo "screenshots: $(ls shots/*.png(N) | wc -l | tr -d ' ')"
