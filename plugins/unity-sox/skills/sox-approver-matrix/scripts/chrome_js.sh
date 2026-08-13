#!/bin/zsh
# chrome_js.sh <js-file>  -- run a JavaScript file in the dedicated capture tab.
#
# Requires Chrome: View > Developer > Allow JavaScript from Apple Events.
# Reading the script from a file avoids the quoting minefield of embedding JS inside
# an AppleScript string inside a shell string.
set +e
HERE="${0:A:h}"
JSFILE="$1"
[[ -r "$JSFILE" ]] || { echo "ERROR: cannot read $JSFILE"; exit 1; }

WID=$(cat "$HERE/.capture_window" 2>/dev/null)
if [[ -z "$WID" ]] || ! osascript -e "tell application \"Google Chrome\" to get id of window id $WID" >/dev/null 2>&1; then
  echo "ERROR: no capture window"; exit 1
fi

# Hand the JS to osascript via a file read, so no escaping is needed.
RESULT=$(osascript <<EOF 2>&1
set jsFile to POSIX file "$(cd "$(dirname "$JSFILE")" && pwd)/$(basename "$JSFILE")"
set fh to open for access jsFile
set js to read fh as «class utf8»
close access fh
tell application "Google Chrome"
  execute (active tab of (window id $WID)) javascript js
end tell
EOF
)
echo "$RESULT"
case "$RESULT" in
  *"not allowed"*|*"turned off"*)
    echo "HINT: enable Chrome > View > Developer > Allow JavaScript from Apple Events" >&2
    exit 1;;
esac
