#!/usr/bin/env bash
# check-update.sh
# Compares the latest GitHub release tag against the current git tag.
# Prints two lines to stdout, CURRENT_TAG and LATEST_TAG.
# Exit 0 = up to date, 1 = update available, 2 = error.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GITHUB_REPO="${GITHUB_REPO}"

if [[ -z "$GITHUB_REPO" ]]; then
    echo "ERROR: GITHUB_REPO not set" >&2
    exit 2
fi

current="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null)"
if [[ -z "$current" ]]; then
    echo "ERROR: could not determine current version via git describe" >&2
    exit 2
fi

api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
response="$(curl -sf --max-time 10 "$api_url" 2>/dev/null)"
if [[ $? -ne 0 || -z "$response" ]]; then
    echo "ERROR: failed to reach GitHub API" >&2
    exit 2
fi

latest="$(printf '%s' "$response" | jq -r '.tag_name // empty')"
if [[ -z "$latest" ]]; then
    echo "ERROR: could not parse tag_name from GitHub response" >&2
    exit 2
fi

echo "$current"
echo "$latest"

current_clean="${current#v}"
latest_clean="${latest#v}"

if [[ "$current_clean" == "$latest_clean" ]]; then
    exit 0
fi

older="$(printf '%s\n%s\n' "$current_clean" "$latest_clean" | sort -V | head -1)"
if [[ "$older" == "$current_clean" ]]; then
    exit 1
fi

exit 0