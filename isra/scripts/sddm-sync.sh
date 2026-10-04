#!/usr/bin/env bash

THEME=isra
DIR="/usr/share/sddm/themes/$THEME"

current=$(cat /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf /etc/sddm.conf 2>/dev/null \
    | awk -F= '/^\[/ { s = $0 } s == "[Theme]" && $1 ~ /^[ \t]*Current[ \t]*$/ { v = $2 } END { gsub(/[ \t\r]/, "", v); print v }')

[[ "$current" == "$THEME" && -x "$DIR/sync.sh" ]] || exit 0
ISRA_SHELL_DIR="$(dirname "$(readlink -f "$0")")/.." exec "$DIR/sync.sh"
