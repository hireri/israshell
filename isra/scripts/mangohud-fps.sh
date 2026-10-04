#!/bin/bash
[[ "$1" =~ ^[0-9]+$ ]] || exit 1

conf="${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud/MangoHud.conf"
mkdir -p "$(dirname "$conf")"

if grep -q '^fps_limit=' "$conf" 2>/dev/null; then
    sed -i "s/^fps_limit=.*/fps_limit=$1/" "$conf"
else
    echo "fps_limit=$1" >> "$conf"
fi
