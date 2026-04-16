#!/bin/bash

INTERVAL=2
TOTAL_DURATION=30
SOURCE_TYPE="monitor"
FIFO=$(mktemp -u /tmp/songrec_out_XXXXXX)
COVER_TEMP=$(mktemp -u /tmp/songrec_cover_XXXXXX.png)
PID_FILE="/tmp/songrec_script.pid"
APP_ICON="audio-x-generic"

cleanup() { rm -f "$FIFO" "$PID_FILE"; }

if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        wait "$OLD_PID" 2>/dev/null
        rm -f "$PID_FILE"
        exit 0
    fi
fi

echo $$ > "$PID_FILE"
trap cleanup EXIT

command -v songrec >/dev/null 2>&1 || exit 1

if [ "$SOURCE_TYPE" = "monitor" ]; then
    AUDIO_DEVICE="$(pactl get-default-sink).monitor"
elif [ "$SOURCE_TYPE" = "input" ]; then
    AUDIO_DEVICE=$(pactl info | awk '/Default Source:/ {print $3}')
else
    exit 1
fi

[ -z "$AUDIO_DEVICE" ] || ! pactl list short sources | grep -q "$AUDIO_DEVICE" && exit 1

mkfifo "$FIFO"
songrec listen --audio-device "$AUDIO_DEVICE" --request-interval "$INTERVAL" --json --disable-mpris > "$FIFO" &
SONGREC_PID=$!
( sleep "$TOTAL_DURATION" && kill "$SONGREC_PID" 2>/dev/null ) &

while IFS= read -r line; do
    echo "$line" | grep -q '"matches": \[' || continue

    TRACK=$(echo "$line" | jq -r '.track.title // "Unknown Track"')
    ARTIST=$(echo "$line" | jq -r '.track.subtitle // "Unknown Artist"')
    ALBUM=$(echo "$line" | jq -r '.track.sections[0].metadata[] | select(.title=="Album") | .text // ""')
    COVER_URL=$(echo "$line" | jq -r '.track.images.coverart // .track.images.background // ""')
    GOOGLE_URL="https://www.google.com/search?q=$(printf '%s' "$TRACK $ARTIST" | sed 's/ /+/g; s/&/%26/g; s/#/%23/g')"

    NOTIFICATION_ICON="$APP_ICON"
    if [ -n "$COVER_URL" ] && curl -sL "$COVER_URL" -o "$COVER_TEMP" 2>/dev/null; then
        file "$COVER_TEMP" | grep -qE "image|PNG|JPEG" && NOTIFICATION_ICON="$COVER_TEMP"
    fi

    BODY="By $ARTIST"
    [ -n "$ALBUM" ] && BODY="$ARTIST\On $ALBUM"

    (
        ACTION=$(notify-send --wait --urgency=normal --icon="$NOTIFICATION_ICON" \
            --app-name="Songrec" --action="open=Find on Google" "$TRACK" "$BODY" 2>/dev/null)
        [ "$ACTION" = "open" ] && xdg-open "$GOOGLE_URL" 2>/dev/null
        rm -f "$COVER_TEMP"
    ) &
    disown

    exit 0

    exit 0
done < "$FIFO"

notify-send --urgency=normal --icon="$APP_ICON" --app-name="Songrec" \
    "No Match Found" "Couldn't identify any song playing"