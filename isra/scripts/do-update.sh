#!/usr/bin/env bash
# do-update.sh
# Pulls latest changes and reloads QuickShell.
# Stdout/stderr are captured by QML for logging.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Fetching tags..."
git -C "$REPO_ROOT" fetch --tags --force origin

current_tag="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "none")"
new_tag="$(git -C "$REPO_ROOT" tag --sort=-v:refname | head -n1)"

if [[ -z "$new_tag" ]]; then
    echo "No tags found." >&2
    exit 1
fi

if [[ "$new_tag" == "$current_tag" ]]; then
    echo "Already up to date at $current_tag"
    echo "done:$current_tag"
    exit 0
fi

echo "Updating: $current_tag -> $new_tag"
git -C "$REPO_ROOT" checkout "$new_tag" 2>&1

notify-send -u low -i software-update-available -a "QuickShell" -t 4000 \
    "Shell updated" "Restarting..."

setsid bash -c '
    sleep 0.5
    kill $(pidof quickshell) 2>/dev/null || true
    sleep 0.2
    qs -n -c isra
' >/dev/null 2>&1 &

setsid bash -c '
    sleep 2
    notify-send -u low -i software-update-available -a "QuickShell" -t 4000 \
        "Shell updated" "Now running '"$new_tag"'"
' >/dev/null 2>&1 &

echo "done:$new_tag"