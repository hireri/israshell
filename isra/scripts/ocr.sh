#!/bin/bash
set -euo pipefail

NOTIFY_OCR_TITLE="${NOTIFY_OCR_TITLE:-OCR}"
NOTIFY_NO_TEXT_FOUND_BODY="${NOTIFY_NO_TEXT_FOUND_BODY:-No text found}"
NOTIFY_COPIED_BODY="${NOTIFY_COPIED_BODY:-Copied to clipboard}"

TMPFILE=$(mktemp --suffix=.png)
trap 'rm -f "$TMPFILE"' EXIT

GEOMETRY="${1:-}"
[[ -z "$GEOMETRY" ]] && exit 0

grim -g "$GEOMETRY" "$TMPFILE" 2>/dev/null || exit 0

text=$(tesseract "$TMPFILE" stdout 2>/dev/null) || true
if [[ -z "$text" ]]; then
    notify-send "$NOTIFY_OCR_TITLE" "$NOTIFY_NO_TEXT_FOUND_BODY" -u normal
    exit 1
fi

printf '%s' "$text" | wl-copy -n
notify-send "$NOTIFY_OCR_TITLE" "$NOTIFY_COPIED_BODY" -i edit-copy