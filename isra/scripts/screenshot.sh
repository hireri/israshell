#!/bin/bash
set -e
[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
    notify-send "Screenshot Error" "Cannot create directory: $OUTPUT_DIR" -u critical -t 3000
    exit 1
}

SELECTION="${1:-}"
[[ -z "$SELECTION" ]] && exit 0

FILENAME="screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

grim -g "$SELECTION" "$FILEPATH" || exit 1
wl-copy < "$FILEPATH"

echo "$FILEPATH"
