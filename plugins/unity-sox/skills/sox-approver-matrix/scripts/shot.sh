#!/bin/zsh
# shot.sh <url|-> <outfile> <expect> [settle] [run]
#
#   <expect>  extended-regex that MUST match text in the image (case-insensitive).
#             Use alternation where a label may OCR poorly, e.g. "Add filter|Show Me".
#   run=1     send Ctrl+Enter (Salesforce Inspector "Run Export") before capturing
#
# Captures the screen area occupied by the dedicated Chrome window, from y=0 so the
# macOS menu-bar clock -- the audit timestamp -- is part of every image.
#
# Two independent safeguards, because each one alone has been fooled here:
#
#  * The region comes from the window's own GLOBAL coordinates, never from a display
#    index. screencapture's -D indexes are not a stable ordering -- with a monitor
#    attached, -D 1 was the built-in screen on one run and the external one on the
#    next -- so index-based rules silently photograph the wrong screen.
#
#  * The image must then contain the expected page text. If it does not, the file is
#    deleted and the shot retried, then abandoned. An interrupted or confused run
#    yields MISSING evidence, never wrong evidence. Earlier versions without this
#    check stored screenshots of Slack and of the operator's own chat window.
set +e
HERE="${0:A:h}"
OCR="$HERE/ocr"
WINFILE="$HERE/.capture_window"
URL="$1"; OUT="$2"; EXPECT="$3"; SETTLE="${4:-10}"; RUN="${5:-0}"; JS="${6:-}"

if [[ -z "$EXPECT" ]]; then
  echo "ABORT: no <expect> marker given for $OUT — refusing to capture blind"; exit 1
fi
if [[ ! -x "$OCR" ]]; then
  echo "ABORT: ocr binary missing — run: swiftc -O -o ocr ocr.swift"; exit 1
fi

win_exists() { osascript -e "tell application \"Google Chrome\" to get id of window id $1" >/dev/null 2>&1; }

# Reuse a dedicated window so the user's own tabs are never navigated.
WID=""
[[ -f "$WINFILE" ]] && WID=$(cat "$WINFILE")
if [[ -z "$WID" ]] || ! win_exists "$WID"; then
  WID=$(osascript -e 'tell application "Google Chrome" to return (id of (make new window)) as string' 2>/dev/null)
  echo "$WID" > "$WINFILE"
fi

if [[ -n "$URL" && "$URL" != "-" ]]; then
  osascript >/dev/null 2>&1 <<EOF
tell application "Google Chrome"
  set URL of active tab of (window id $WID) to "$URL"
end tell
EOF
  sleep "$SETTLE"
fi

# Optional page preparation (e.g. opening the report builder's Filters tab, which
# needs a click that macOS will not let us synthesise).
if [[ -n "$JS" ]]; then
  JS_RESULT=$("$HERE/chrome_js.sh" "$HERE/$JS" 2>&1)
  echo "   js($JS): $JS_RESULT"
  case "$JS_RESULT" in
    *not-found*|*ERROR*|*"not allowed"*)
      echo "ABORT: page preparation failed for $OUT"; exit 1;;
  esac
  # Clicking is not the same as rendered. On the heaviest report the panel had not
  # painted before the shutter fired, so the shot failed verification even though the
  # click succeeded. The preparation scripts are idempotent and report "already-open"
  # once their panel is present, so re-running one is also the readiness probe -- poll
  # it rather than guessing at a sleep duration.
  for _ in {1..10}; do
    sleep 2
    [[ "$("$HERE/chrome_js.sh" "$HERE/$JS" 2>&1)" == *already-open* ]] && break
  done
fi

# The region of the screen to photograph, in GLOBAL coordinates, derived from the
# Chrome window's own bounds.
#
# This deliberately avoids screencapture's -D display index. Those indexes are not a
# stable ordering: with an external monitor attached, -D 1 was the built-in display on
# one run and the external one on the next, so any index-based rule silently
# photographs the wrong screen. Global coordinates have no such ambiguity.
#
# Height runs from y=0 so the macOS menu bar -- the audit timestamp -- is included.
capture_region() {
  osascript <<EOF 2>/dev/null
tell application "Google Chrome"
  set b to bounds of (window id $WID)
  set x1 to item 1 of b
  set x2 to item 3 of b
  set y2 to item 4 of b
  return (x1 as string) & "," & "0" & "," & ((x2 - x1) as string) & "," & (y2 as string)
end tell
EOF
}

capture_attempt() {  # capture_attempt <outfile>
  local out="$1" region tmp
  region=$(capture_region)
  if [[ -z "$region" ]]; then
    echo "   (cannot read the Chrome window's position — not capturing)"
    return 1
  fi
  tmp="${out}.tmp"
  screencapture -x -t png -R "$region" "$tmp" 2>/dev/null
  [[ -s "$tmp" ]] || { rm -f "$tmp"; return 1; }
  if "$OCR" "$tmp" 2>/dev/null | grep -qiE -- "$EXPECT"; then
    mv "$tmp" "$out"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

for attempt in 1 2 3; do
  osascript >/dev/null 2>&1 <<EOF
tell application "Google Chrome"
  set index of (window id $WID) to 1
  activate
end tell
EOF
  sleep 2

  if [[ "$RUN" == "1" && "$attempt" == "1" ]]; then
    osascript -e 'tell application "System Events" to keystroke return using control down' >/dev/null 2>&1 \
      || { echo "ABORT: keystroke blocked (Accessibility permission)"; exit 1; }
    sleep 6
  fi

  if capture_attempt "$OUT"; then
    echo "OK $OUT"
    exit 0
  fi
  sleep 3
done

rm -f "$OUT" "${OUT}.tmp" 2>/dev/null
echo "ABORT: '$EXPECT' not found in the captured area for $OUT — no image kept"
exit 1
