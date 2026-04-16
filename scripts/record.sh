#!/bin/bash
PIDFILE="/tmp/wl-screenrec-region.pid"
TIMERPID_FILE="/tmp/wl-screenrec-region.timer.pid"
FILEPATH_FILE="/tmp/wl-screenrec-region.filepath"
OUTPUT_DIR="$HOME/Videos/Recordings"
GIF_DIR="$HOME/Videos/Recordings/GIFs"
THUMB="/tmp/wl-screenrec-thumb.jpg"
MAX_DURATION=300

mkdir -p "$OUTPUT_DIR" "$GIF_DIR"
mkdir -p "$OUTPUT_DIR"

get_audio_device() {
    pactl list short sources 2>/dev/null \
        | awk '/\.monitor.*RUNNING/ {print $2; exit}'
}

convert_to_gif() {
    local input="$1"
    local basename="${input%.mp4}"
    local basename="${basename##*/}"
    local output="$GIF_DIR/${basename}.gif"

    notify-send "Converting to GIF…" "${input##*/}" \
        -i "video-x-generic" \
        -a "Screen Recorder" \
        -t 4000

    ffmpeg -i "$input" \
        -vf "fps=15,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -loop 0 \
        -y "$output" 2>/dev/null

    if [ $? -eq 0 ]; then
        ACTION=$(notify-send \
            -A "open=Open GIF" \
            -A "folder=View Folder" \
            "GIF saved" "${basename}.gif" \
            -i "image-gif" \
            -a "Screen Recorder" \
            -t 10000)
        case "$ACTION" in
            open)   xdg-open "$output" ;;
            folder) xdg-open "$GIF_DIR" ;;
        esac
    else
        notify-send "GIF conversion failed" "ffmpeg error" \
            -i "dialog-error" \
            -a "Screen Recorder" \
            -t 6000
    fi
}

stop_recording() {
    kill -INT "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"

    if [ -f "$TIMERPID_FILE" ]; then
        kill "$(cat "$TIMERPID_FILE")" 2>/dev/null
        rm -f "$TIMERPID_FILE"
    fi

    sleep 1

    LATEST=$(cat "$FILEPATH_FILE" 2>/dev/null)
    rm -f "$FILEPATH_FILE"

    if [ -z "$LATEST" ] || [ ! -f "$LATEST" ]; then
        notify-send "Recording saved" "Saved to $OUTPUT_DIR" \
            -i "video-x-generic" \
            -a "Screen Recorder" \
            -t 8000
        exit 0
    fi

    DURATION=$(ffprobe -v error -select_streams v:0 \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 \
        "$LATEST" 2>/dev/null | cut -d. -f1)

    MIDPOINT=$(( ${DURATION:-2} / 2 ))
    ffmpeg -ss "$MIDPOINT" -i "$LATEST" \
        -vframes 1 -q:v 2 -y "$THUMB" 2>/dev/null

    FILENAME="${LATEST##*/}"

    if [ -n "$DURATION" ] && [ "$DURATION" -lt 16 ] 2>/dev/null; then
        ACTION=$(notify-send \
            -A "open=Open" \
            -A "gif=To GIF" \
            "Recording saved" \
            "<img src=\"$THUMB\"/>Saved to $OUTPUT_DIR" \
            -i "video-x-generic" \
            -a "Screen Recorder" \
            -t 10000)
    else
        ACTION=$(notify-send \
            -A "open=Open" \
            "Recording saved" \
            "<img src=\"$THUMB\"/>Saved to $OUTPUT_DIR" \
            -i "video-x-generic" \
            -a "Screen Recorder" \
            -t 10000)
    fi

    case "$ACTION" in
        open) xdg-open "$LATEST" ;;
        gif)  convert_to_gif "$LATEST" ;;
    esac
}

if [ -f "$PIDFILE" ]; then
    stop_recording
else
    GEOMETRY=$(slurp -d)
    if [ -n "$GEOMETRY" ]; then
        AUDIO_DEVICE=$(get_audio_device)
        FILEPATH="$OUTPUT_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
        echo "$FILEPATH" > "$FILEPATH_FILE"

        if [ -n "$AUDIO_DEVICE" ]; then
            wl-screenrec -g "$GEOMETRY" \
                --audio --audio-device "$AUDIO_DEVICE" \
                --max-fps 60 \
                --filename "$FILEPATH" &
        else
            notify-send "Warning" "No active audio monitor found, recording without audio" \
                -i "dialog-warning" \
                -a "Screen Recorder" \
                -t 6000
            wl-screenrec -g "$GEOMETRY" \
                --max-fps 60 \
                --filename "$FILEPATH" &
        fi

        REC_PID=$!
        echo $REC_PID > "$PIDFILE"

        ( sleep $MAX_DURATION && \
          [ -f "$PIDFILE" ] && \
          notify-send "Recording limit reached" "Auto stopping at 5 minutes" \
              -i "dialog-warning" \
              -a "Screen Recorder" \
              -t 6000 && \
          stop_recording ) &
        echo $! > "$TIMERPID_FILE"

        notify-send "Recording started" "Recording region..." \
            -i "media-record" \
            -a "Screen Recorder" \
            -t 3000
    fi
fi