#!/usr/bin/env bash
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

WALL_HASH=$(md5sum "$WALL" | cut -d' ' -f1)
OUT="/tmp/qs_scheme_previews_${WALL_HASH}_${MODE}.json"

[[ -f "$OUT" ]] && { echo "$OUT"; exit 0; }

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

for SCHEME in "${VALID_SCHEMES[@]}"; do
  (
    raw=$(matugen image "$WALL" --dry-run --json hex --source-color-index 0 \
            -t "$SCHEME" -m "$MODE" 2>&1)

    primary=$(  jq -r ".colors.primary.${MODE}.color"   <<< "$raw")
    secondary=$(jq -r ".colors.secondary.${MODE}.color" <<< "$raw")
    tertiary=$( jq -r ".colors.tertiary.${MODE}.color"  <<< "$raw")

    [[ "$primary" == "null" || "$secondary" == "null" || "$tertiary" == "null" ]] && exit 0
    [[ -z "$primary"       || -z "$secondary"         || -z "$tertiary"        ]] && exit 0

    printf '"%s":{"primary":"%s","secondary":"%s","tertiary":"%s"}' \
      "$SCHEME" "$primary" "$secondary" "$tertiary" \
      > "$TMPDIR_WORK/$SCHEME"
  ) &
done
wait

result="{"
first=1
for SCHEME in "${VALID_SCHEMES[@]}"; do
  [[ $first -eq 0 ]] && result+=","
  result+=$(cat "$TMPDIR_WORK/$SCHEME")
  first=0
done
result+="}"

echo "$result" > "$OUT"
echo "$OUT"