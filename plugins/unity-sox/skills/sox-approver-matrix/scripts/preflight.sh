#!/bin/zsh
# preflight.sh — verify every prerequisite before the control runs.
#
# Each check reports PASS/FAIL and, on failure, the exact fix. run.sh runs this
# automatically and refuses to start if anything fails. Nothing here changes a
# setting: the permissions below can only be granted by the person at the keyboard.
cd "${0:A:h}"
set +e
setopt NULL_GLOB

CFG=../config.json
PASS=0; FAIL=0
ok()   { print -P "  %F{green}PASS%f  $1"; PASS=$(( PASS + 1 )); }
bad()  { print -P "  %F{red}FAIL%f  $1"; print "        fix: $2"; FAIL=$(( FAIL + 1 )); }
warn() { print -P "  %F{yellow}NOTE%f  $1"; }

echo "SOX Approver Matrix — preflight"
echo "=============================================================="

# 0 ------------------------------------------------------------------- setup
if [[ -x ./venv/bin/python ]] && ./venv/bin/python -c "import openpyxl, PIL" >/dev/null 2>&1; then
  ok "Python environment (openpyxl, Pillow)"
else
  bad "Python environment is not set up" "run ./setup.sh"
fi

if [[ -x ./ocr ]]; then
  ok "OCR helper is built"
elif command -v swiftc >/dev/null 2>&1; then
  warn "OCR helper not built — setup.sh or the first run will build it"
else
  bad "Swift compiler not found, so the OCR helper cannot be built" \
      "xcode-select --install, then ./setup.sh"
fi

EXTID=$(./venv/bin/python -c "import json;print(json.load(open('$CFG'))['org']['inspector_extension_id'])" 2>/dev/null)

# 1 ---------------------------------------------------------------- screenshots
# NB: screencapture silently refuses any filename beginning with a dot.
if screencapture -x -t png /tmp/pf_probe.png 2>/dev/null && [[ -s /tmp/pf_probe.png ]]; then
  ok "Screen Recording permission (screenshots work)"
else
  bad "Screen Recording permission is missing — screenshots cannot be taken" \
      "System Settings > Privacy & Security > Screen Recording > enable Claude (or your terminal), then quit and reopen it"
fi
rm -f /tmp/pf_probe.png

# 2 --------------------------------------------------------------- keystrokes
if osascript -e 'tell application "System Events" to key code 48' >/dev/null 2>&1; then
  ok "Accessibility permission (keystrokes work — needed to run Salesforce Inspector)"
else
  bad "Accessibility permission is missing — cannot send Ctrl+Enter to Salesforce Inspector" \
      "System Settings > Privacy & Security > Accessibility > enable Claude (or your terminal), then quit and reopen it"
fi

# 3 ------------------------------------------------------------------- Chrome
if pgrep -x "Google Chrome" >/dev/null 2>&1; then
  ok "Google Chrome is running"
else
  bad "Google Chrome is not running" "Open Chrome and sign in to Salesforce PRODUCTION"
fi

# 4 ------------------------------------------- Chrome JavaScript from AppleScript
JS_TEST=$(osascript -e 'tell application "Google Chrome" to execute (active tab of front window) javascript "1+1"' 2>&1)
if [[ "$JS_TEST" == "2" ]]; then
  ok "Chrome: Allow JavaScript from Apple Events"
else
  bad "Chrome will not run JavaScript from AppleScript — the Filters screenshots and the permissions data cannot be captured" \
      "In Chrome's macOS MENU BAR at the top of the screen (not the ⋮ menu): View > Developer > Allow JavaScript from Apple Events"
fi

# 5 ------------------------------------------------------- Salesforce Inspector
if ls "$HOME/Library/Application Support/Google/Chrome"/*/Extensions/"$EXTID" >/dev/null 2>&1; then
  ok "Salesforce Inspector Reloaded extension is installed"
else
  warn "Could not confirm Salesforce Inspector Reloaded (extension id $EXTID)"
  warn "      If the Modify All screenshots fail, install it from the Chrome Web Store."
fi

# 6 -------------------------------------------------------- Salesforce session
SF=$(osascript -e 'tell application "Google Chrome"
  set n to 0
  repeat with w in windows
    repeat with t in tabs of w
      if (URL of t) contains "force.com" or (URL of t) contains "salesforce" then set n to n + 1
    end repeat
  end repeat
  return n as string
end tell' 2>/dev/null)
if [[ -n "$SF" && "$SF" -gt 0 ]]; then
  ok "A Salesforce tab is open (session should be live)"
else
  warn "No Salesforce tab open — if the session has expired the run will capture login pages"
  warn "      Open Salesforce PRODUCTION and confirm you are logged in before running."
fi

# 7 ------------------------------------------------------------------ displays
NDISP=$(screencapture -x -t png -D 99 /dev/null 2>&1 | grep -oE '[0-9]+' | tail -1)
[[ -z "$NDISP" ]] && NDISP=1
if [[ "$NDISP" -gt 1 ]]; then
  warn "$NDISP displays connected. Screenshots come from whichever display Chrome is on."
  warn "      Do not connect or disconnect a monitor while the control is running."
fi

echo "=============================================================="
print -P "  %F{green}$PASS passed%f, %F{red}$FAIL failed%f"
echo
echo "While the control runs (about 10 minutes):"
echo "  - do not use the keyboard, mouse or Chrome"
echo "  - park the mouse pointer in a corner of the screen"
echo "  - close the output workbooks if they are open in Excel"
echo "The run drives its own Chrome window and never touches your tabs, but it"
echo "captures whole screens, so anything in front will end up in the evidence."
echo

[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
