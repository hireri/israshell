#!/bin/bash
set -e

NOTIFY_ERROR_TITLE="${NOTIFY_SCREENSHOT_ERROR_TITLE:-Screenshot Error}"
NOTIFY_ERROR_BODY="${NOTIFY_SCREENSHOT_ERROR_BODY:-Cannot create directory: %s}"

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
    notify-send "$NOTIFY_ERROR_TITLE" "$(printf "$NOTIFY_ERROR_BODY" "$OUTPUT_DIR")" -u critical -t 3000
    exit 1
}

SELECTION="${1:-}"
[[ -z "$SELECTION" ]] && exit 0

FILENAME="screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"

grim -g "$SELECTION" "$FILEPATH" || exit 1
wl-copy < "$FILEPATH"

echo "$FILEPATH"
