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

echo "done:$new_tag"