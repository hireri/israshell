#!/usr/bin/env bash
# apply-wallpaper.sh <wall-path> <mode> [scheme]
#   mode: dark | light

set -euo pipefail

WALL=$(readlink -f "${1:?Wall path required}")
MODE="${2:-dark}"
SCHEME="${3:-scheme-tonal-spot}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VALID_SCHEMES=(
    scheme-content
    scheme-expressive
    scheme-fidelity
    scheme-fruit-salad
    scheme-monochrome
    scheme-neutral
    scheme-rainbow
    scheme-tonal-spot
    scheme-vibrant
)

is_valid_scheme() {
    local s="$1"
    for v in "${VALID_SCHEMES[@]}"; do
        [[ "$v" == "$s" ]] && return 0
    done
    return 1
}

if ! is_valid_scheme "$SCHEME"; then
    echo "[apply-wallpaper] Invalid scheme '$SCHEME', falling back to scheme-tonal-spot" >&2
    SCHEME="scheme-tonal-spot"
fi

ln -sf "$WALL" "$HOME/.config/hypr/current_wall"

awww img \
    --transition-type     grow \
    --transition-fps      60   \
    --transition-duration 1    \
    "$HOME/.config/hypr/current_wall"

matugen image "$HOME/.config/hypr/current_wall" -m "$MODE" -t "$SCHEME" --source-color-index 0

if [ "$MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi
