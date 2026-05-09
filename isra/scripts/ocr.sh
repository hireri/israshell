#!/bin/bash
set -euo pipefail

TMPFILE=$(mktemp --suffix=.png)
trap 'rm -f "$TMPFILE"' EXIT

if ! grim -g "$(slurp)" "$TMPFILE" 2>/dev/null; then
	exit 0
fi

if ! text=$(tesseract "$TMPFILE" stdout 2>/dev/null) || [ -z "$text" ]; then
	notify-send "OCR" "No text found" -u normal
	exit 1
fi

printf '%s' "$text" | wl-copy -n
notify-send "OCR" "Copied to clipboard" -i edit-copy
