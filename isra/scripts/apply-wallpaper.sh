#!/usr/bin/env bash
# apply-wallpaper.sh <wall-path> <mode> [scheme] [source-color-index] [--awww]
#   mode: dark | light

set -euo pipefail

USE_AWWW="false"
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--awww" || "$arg" == "-awww" ]]; then
        USE_AWWW="true"
    else
        ARGS+=("$arg")
    fi
done
set -- "${ARGS[@]}"

WALL=$(readlink -f "${1:?Wall path required}")
MODE="${2:-dark}"
SCHEME="${3:-scheme-tonal-spot}"
SOURCE_INDEX="${4:-0}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

FRAME_CACHE_DIR="$HOME/.cache/isra/wallpaper-frames"

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

is_video() {
    case "${1,,}" in
        *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v) return 0 ;;
        *) return 1 ;;
    esac
}

get_preview_frame() {
    local video="$1"
    mkdir -p "$FRAME_CACHE_DIR"
    local key
    key=$(printf '%s' "$video" | sha256sum | cut -d' ' -f1)
    local frame="$FRAME_CACHE_DIR/$key.png"

    if [ -s "$frame" ]; then
        printf '%s' "$frame"
        return 0
    fi

    if ffmpeg -y -i "$video" -vf "thumbnail" -frames:v 1 "$frame" \
        -loglevel error; then
        printf '%s' "$frame"
        return 0
    fi

    echo "[apply-wallpaper] ffmpeg frame extraction failed for '$video'; no static preview available" >&2
    return 1
}

SKIP_THEME=0
if is_video "$WALL"; then
    if PREVIEW=$(get_preview_frame "$WALL"); then
        :
    else
        SKIP_THEME=1
    fi
else
    PREVIEW="$WALL"
fi

ln -sf "$WALL" "$HOME/.config/hypr/current_wall"
if [ "$SKIP_THEME" -eq 0 ]; then
    ln -sf "$PREVIEW" "$HOME/.config/hypr/current_wall_prev"
fi

if [ "$USE_AWWW" = "true" ]; then
    if ! pgrep -x "awww-daemon" &>/dev/null; then
        echo "[apply-wallpaper] awww-daemon not running; starting it..."
        awww-daemon &>/dev/null &
        disown
        sleep 0.5
    fi

    AWWW_TARGET="$HOME/.config/hypr/current_wall_prev"
    if ! is_video "$WALL"; then
        AWWW_TARGET="$HOME/.config/hypr/current_wall"
    fi

    awww img \
        --transition-type     grow \
        --transition-fps      60   \
        --transition-duration 1    \
        "$AWWW_TARGET"
else
    if pgrep -x "awww-daemon" &>/dev/null; then
        echo "[apply-wallpaper] awww flag not passed; stopping awww-daemon..."
        awww kill &>/dev/null || pkill -x "awww-daemon" || true
    fi
fi

if [ "$MODE" = "dark" ]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi

if [ "$SKIP_THEME" -eq 1 ]; then
    echo "[apply-wallpaper] no static preview for '$WALL'; keeping previous theme" >&2
    exit 1
fi

matugen image "$HOME/.config/hypr/current_wall_prev" -m "$MODE" -t "$SCHEME" --source-color-index "$SOURCE_INDEX"