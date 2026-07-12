#!/usr/bin/env bash
# apply-wallpaper.sh <wall-path> <mode> [scheme] [source-color-index] [--awww]
#   mode: dark | light

set -euo pipefail

USE_AWWW="false"
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --awww|-awww) USE_AWWW="true" ;;
        *) ARGS+=("$arg") ;;
    esac
done
set -- "${ARGS[@]}"

WALL_ARG="${1:?Wall path required}"
WALL=$(readlink -f "$WALL_ARG")
MODE="${2:-dark}"
SCHEME="${3:-scheme-tonal-spot}"
SOURCE_INDEX="${4:-0}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

FRAME_CACHE_DIR="$HOME/.cache/isra/wallpaper-frames"
HYPR_DIR="$HOME/.config/hypr"

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

is_video() {
    case "${1,,}" in
        *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v) return 0 ;;
        *) return 1 ;;
    esac
}

get_preview_frame() {
    if [[ $# -ne 1 ]]; then
        echo "[apply-wallpaper] get_preview_frame: expected 1 arg, got $#" >&2
        return 1
    fi
    local video=$1

    mkdir -p "$FRAME_CACHE_DIR"

    local key frame
    key=$(sha256sum <<<"$video" | cut -d' ' -f1)
    frame="$FRAME_CACHE_DIR/$key.png"

    if [[ -s "$frame" ]]; then
        printf '%s\n' "$frame"
        return 0
    fi

    local duration_raw duration seek
    duration_raw=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null || true)
    duration="${duration_raw%.*}"
    duration="${duration:-0}"

    seek=2
    if (( duration < 4 )); then
        seek=0
    fi

    if ffmpeg -y -ss "$seek" -i "$video" -frames:v 1 "$frame" -loglevel error; then
        printf '%s\n' "$frame"
        return 0
    fi

    echo "[apply-wallpaper] ffmpeg frame extraction failed for '$video'; no static preview available" >&2
    return 1
}

manage_awww_daemon() {
    if [[ "$USE_AWWW" != "true" ]]; then
        if pgrep -x "awww-daemon" &>/dev/null; then
            echo "[apply-wallpaper] awww flag not passed; stopping awww-daemon..."
            awww kill &>/dev/null || pkill -x "awww-daemon" || true
        fi
        return 0
    fi

    if ! pgrep -x "awww-daemon" &>/dev/null; then
        echo "[apply-wallpaper] awww-daemon not running; starting it..."
        awww-daemon &>/dev/null &
        disown
        sleep 0.5
    fi

    local target="$HYPR_DIR/current_wall_prev"
    is_video "$WALL" || target="$HYPR_DIR/current_wall"

    awww img \
        --transition-type     grow \
        --transition-fps      60   \
        --transition-duration 1    \
        "$target"
}

if ! is_valid_scheme "$SCHEME"; then
    echo "[apply-wallpaper] Invalid scheme '$SCHEME', falling back to scheme-tonal-spot" >&2
    SCHEME="scheme-tonal-spot"
fi

SKIP_THEME=0
PREVIEW=""

if is_video "$WALL"; then
    if PREVIEW=$(get_preview_frame "$WALL"); then
        :
    else
        SKIP_THEME=1
    fi
else
    PREVIEW="$WALL"
fi

ln -sf "$WALL" "$HYPR_DIR/current_wall"
if [[ "$SKIP_THEME" -eq 0 ]]; then
    ln -sf "$PREVIEW" "$HYPR_DIR/current_wall_prev"
fi

manage_awww_daemon

if [[ "$MODE" == "dark" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi

if [[ "$SKIP_THEME" -eq 1 ]]; then
    echo "[apply-wallpaper] no static preview for '$WALL'; keeping previous theme" >&2
    exit 1
fi

matugen image "$HYPR_DIR/current_wall_prev" -m "$MODE" -t "$SCHEME" --source-color-index "$SOURCE_INDEX"