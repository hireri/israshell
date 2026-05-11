#!/bin/bash
set -euo pipefail

TMPFILE=$(mktemp --suffix=.png)
trap 'rm -f "$TMPFILE"' EXIT

GEOMETRY="${1:-}"
[[ -z "$GEOMETRY" ]] && exit 0

grim -g "$GEOMETRY" "$TMPFILE" 2>/dev/null || exit 0

text=$(tesseract "$TMPFILE" stdout 2>/dev/null) || true
if [[ -z "$text" ]]; then
    notify-send "OCR" "No text found" -u normal
    exit 1
fi

printf '%s' "$text" | wl-copy -n
notify-send "OCR" "Copied to clipboard" -i edit-copy