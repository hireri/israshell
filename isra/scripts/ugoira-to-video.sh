#!/usr/bin/env bash
# ugoira-to-video.sh <zip-path> <output-mp4-path>
# Converts a Danbooru ugoira zip into a video.
set -euo pipefail

ZIP="${1:?zip path required}"
OUT="${2:?output path required}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

unzip -qq -o "$ZIP" -d "$TMPDIR"

JSON=$(find "$TMPDIR" -maxdepth 1 -iname '*.json' | head -n1)
if [[ -z "$JSON" ]]; then
    echo "ugoira-to-video: no frame-timing json found in zip" >&2
    exit 1
fi

CONCAT="$TMPDIR/concat.txt"
jq -r '.frames[] | "file '\''\(.file)'\''\nduration \((.delay // 100) / 1000)"' "$JSON" > "$CONCAT"

LAST_FILE=$(jq -r '.frames[-1].file' "$JSON")
echo "file '$LAST_FILE'" >> "$CONCAT"

if [[ ! -s "$CONCAT" ]]; then
    echo "ugoira-to-video: empty frame list" >&2
    exit 1
fi

ffmpeg -y -f concat -safe 0 -i "$CONCAT" -fps_mode vfr -pix_fmt yuv420p -c:v libx264 -crf 20 -preset veryfast "$OUT" -loglevel error

printf '%s' "$OUT"
