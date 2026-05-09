#!/usr/bin/env bash
# do-update.sh
# Pulls latest changes and reloads QuickShell.
# Stdout/stderr are captured by QML for logging.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

set -euo pipefail

echo "Pulling latest changes..."
git -C "$REPO_ROOT" pull --ff-only 2>&1

new_tag="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "unknown")"
echo "Now at: $new_tag"

notify-send -u low -i software-update-available -a "QuickShell" -t 4000 \
    "Shell updated" "Restarting..."

(
    sleep 0.5
    kill $(pidof quickshell) 2>/dev/null || true
    sleep 0.2
    qs -c isra
) >/dev/null 2>&1 &
disown

(
    sleep 2
    notify-send -u low -i software-update-available -a "QuickShell" -t 4000 \
        "Shell updated" "Now running $new_tag"
) >/dev/null 2>&1 &
disown

echo "done:$new_tag"