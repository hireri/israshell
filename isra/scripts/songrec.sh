#!/bin/bash

NOTIFY_FIND_ON_GOOGLE_ACTION="${NOTIFY_FIND_ON_GOOGLE_ACTION:-Find on Google}"
NOTIFY_NO_MATCH_TITLE="${NOTIFY_NO_MATCH_TITLE:-No Match Found}"
NOTIFY_NO_MATCH_FILE_BODY="${NOTIFY_NO_MATCH_FILE_BODY:-Couldn't identify the song in this file}"
NOTIFY_NO_MATCH_LIVE_BODY="${NOTIFY_NO_MATCH_LIVE_BODY:-Couldn't identify any song playing}"

INTERVAL=2
TOTAL_DURATION=30
SOURCE_TYPE="monitor"
FIFO=$(mktemp -u /tmp/songrec_out_XXXXXX)
PID_FILE="/tmp/songrec_script.pid"
APP_ICON="audio-x-generic"

notify_track() {
    local TRACK="$1" ARTIST="$2" ALBUM="$3" COVER_URL="$4"
    local COVER_TEMP=$(mktemp -u /tmp/songrec_cover_XXXXXX.png)
    local GOOGLE_URL="https://www.google.com/search?q=$(printf '%s' "$TRACK $ARTIST" | sed 's/ /+/g; s/&/%26/g; s/#/%23/g')"

    local NOTIFICATION_ICON="$APP_ICON"
    if [ -n "$COVER_URL" ] && curl -sL "$COVER_URL" -o "$COVER_TEMP" 2>/dev/null; then
        file "$COVER_TEMP" | grep -qE "image|PNG|JPEG" && NOTIFICATION_ICON="$COVER_TEMP"
    fi

    local BODY="$ARTIST"
    [ -n "$ALBUM" ] && BODY="$ALBUM\n$ARTIST"

    (
        ACTION=$(notify-send --wait --urgency=normal --icon="$NOTIFICATION_ICON" \
            --app-name="Songrec" --action="open=$NOTIFY_FIND_ON_GOOGLE_ACTION" "$TRACK" "$BODY" 2>/dev/null)
        [ "$ACTION" = "open" ] && xdg-open "$GOOGLE_URL" 2>/dev/null
        rm -f "$COVER_TEMP"
    ) &
    disown
}

notify_no_match() {
    notify-send --urgency=normal --icon="$APP_ICON" --app-name="Songrec" \
        "$NOTIFY_NO_MATCH_TITLE" "$1"
}

if [ -n "$1" ]; then
    [ -f "$1" ] || exit 1
    command -v songrec >/dev/null 2>&1 || exit 1

    RESULT=$(songrec audio-file-to-recognized-song "$1" 2>/dev/null)
    MATCHED=$(echo "$RESULT" | jq -e '.matches | length > 0' 2>/dev/null)

    if [ "$MATCHED" != "true" ]; then
        notify_no_match "$NOTIFY_NO_MATCH_FILE_BODY"
        exit 0
    fi

    TRACK=$(echo "$RESULT" | jq -r '.track.title // "Unknown Track"')
    ARTIST=$(echo "$RESULT" | jq -r '.track.subtitle // "Unknown Artist"')
    ALBUM=$(echo "$RESULT" | jq -r '.track.sections[0].metadata[] | select(.title=="Album") | .text // ""')
    COVER_URL=$(echo "$RESULT" | jq -r '.track.images.coverart // .track.images.background // ""')

    notify_track "$TRACK" "$ARTIST" "$ALBUM" "$COVER_URL"
    exit 0
fi

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
    echo "$line" | jq -e '.matches' > /dev/null 2>&1 || continue

    TRACK=$(echo "$line" | jq -r '.track.title // "Unknown Track"')
    ARTIST=$(echo "$line" | jq -r '.track.subtitle // "Unknown Artist"')
    ALBUM=$(echo "$line" | jq -r '.track.sections[0].metadata[] | select(.title=="Album") | .text // ""')
    COVER_URL=$(echo "$line" | jq -r '.track.images.coverart // .track.images.background // ""')

    notify_track "$TRACK" "$ARTIST" "$ALBUM" "$COVER_URL"

    exit 0
done < "$FIFO"

notify_no_match "$NOTIFY_NO_MATCH_LIVE_BODY"