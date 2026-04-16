#!/usr/bin/env bash
set -euo pipefail

TMPFILE=$(mktemp --suffix=.png)
trap 'rm -f "$TMPFILE"' EXIT

if ! grim -g "$(slurp)" "$TMPFILE" 2>/dev/null; then
	exit 0
fi

if ! url=$(curl -fsS -m 30 -F "files[]=@$TMPFILE" 'https://uguu.se/upload' 2>/dev/null | jq -er '.files[0].url'); then
	notify-send "Upload Failed" "Could not upload image" -u critical
	exit 1
fi

xdg-open "https://lens.google.com/uploadbyurl?url=$url"