#!/usr/bin/env bash
# gen-scheme-previews.sh <wall-path> <mode>
#   mode: dark | light

set -euo pipefail

WALL=$(readlink -f "${1:?Wall path required}")
MODE="${2:-dark}"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VALID_SCHEMES=(
    scheme-content
    scheme-expressive
    scheme-fruit-salad
    scheme-monochrome
    scheme-vibrant
    scheme-tonal-spot
)
    
WALL_HASH=$(echo -n "$WALL" | md5sum | cut -d' ' -f1)
OUT="/tmp/qs_scheme_previews_${WALL_HASH}_${MODE}.json"

if [[ -f "$OUT" ]]; then
    echo "$OUT"
    exit 0
fi

result="{"
first=1

for SCHEME in "${VALID_SCHEMES[@]}"; do
    raw=$(matugen image "$WALL" --dry-run --json hex --source-color-index 0 -t "$SCHEME" -m "$MODE" 2>/dev/null) || {
        echo "[gen-scheme-previews] matugen failed for $SCHEME" >&2
        continue
    }

    primary=$(echo "$raw"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['colors']['primary']['${MODE}']['color'])"   2>/dev/null || echo "")
    secondary=$(echo "$raw" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['colors']['secondary']['${MODE}']['color'])" 2>/dev/null || echo "")
    tertiary=$(echo "$raw"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['colors']['tertiary']['${MODE}']['color'])"  2>/dev/null || echo "")

    [[ -z "$primary" || -z "$secondary" || -z "$tertiary" ]] && continue

    [[ $first -eq 0 ]] && result+=","
    result+="\"$SCHEME\":{\"primary\":\"$primary\",\"secondary\":\"$secondary\",\"tertiary\":\"$tertiary\"}"
    first=0
done

result+="}"

echo "$result" > "$OUT"
echo "$OUT"
