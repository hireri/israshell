#!/bin/bash
set -e
video="$1"
cache_dir="$HOME/.cache/israshell/video-frames"
mkdir -p "$cache_dir"
mtime=$(stat -c '%Y' "$video" 2>/dev/null || echo 0)
key=$(printf '%s:%s' "$video" "$mtime" | sha256sum | cut -d' ' -f1)
frame="$cache_dir/$key.png"
dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null | cut -d. -f1)
if [ -s "$frame" ]; then printf '%s\n%s' "$frame" "$dur"; exit 0; fi
ffmpeg -y -i "$video" -vf "thumbnail,scale=320:-1" -frames:v 1 "$frame" -loglevel error >/dev/null 2>&1 && printf '%s\n%s' "$frame" "$dur"
