#!/bin/bash
set -euo pipefail

TMPFILE=$(mktemp --suffix=.png)
trap 'rm -f "$TMPFILE"' EXIT

GEOMETRY="${1:-}"
[[ -z "$GEOMETRY" ]] && exit 0

grim -g "$GEOMETRY" "$TMPFILE" 2>/dev/null || exit 0

url=$(curl -fsS -m 30 -F "files[]=@$TMPFILE" 'https://uguu.se/upload' 2>/dev/null \
    | jq -er '.files[0].url') || {
    notify-send "Upload Failed" "Could not upload image" -u critical
    exit 1
}

xdg-open "https://lens.google.com/uploadbyurl?url=$url"
