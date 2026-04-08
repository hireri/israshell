#!/usr/bin/env bash
# $ apply-wallpaper.sh <wall-path> <mode>
#   L mode: dark | light
set -euo pipefail

WALL="${1:?Wall path required}"
MODE="${2:-dark}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

ln -sf "$WALL" "$HOME/.config/hypr/current_wall"

awww img \
    --transition-type  fade \
    --transition-fps   180  \
    --transition-duration 2 \
    "$HOME/.config/hypr/current_wall"

matugen image "$HOME/.config/hypr/current_wall" -m "$MODE"
