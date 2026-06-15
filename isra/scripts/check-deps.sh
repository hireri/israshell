#!/usr/bin/env bash
# check-deps.sh
# Reads deps from $REPO_ROOT/deps, checks each via `yay -Q`.
# Prints missing package names to stdout, one per line.
# Exit 0 = all present, 1 = one or more missing, 2 = error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPS_FILE="$REPO_ROOT/deps"

if [[ ! -f "$DEPS_FILE" ]]; then
    echo "ERROR: deps file not found at $DEPS_FILE" >&2
    exit 2
fi

missing=()

while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    pkg="$line"
    if ! yay -Q "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
        missing+=("$pkg")
    fi
done < "$DEPS_FILE"

if [[ ${#missing[@]} -gt 0 ]]; then
    printf '%s\n' "${missing[@]}"
    exit 1
fi

exit 0