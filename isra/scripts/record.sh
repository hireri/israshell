#!/bin/bash
PIDFILE="/tmp/screenrec-region.pid"
TIMERPID_FILE="/tmp/screenrec-region.timer.pid"
FILEPATH_FILE="/tmp/screenrec-region.filepath"
OUTPUT_DIR="$HOME/Videos/Recordings"
GIF_DIR="$HOME/Videos/Recordings/GIFs"
THUMB="/tmp/screenrec-thumb.jpg"
MAX_DURATION=300
MAX_W=1920
MAX_H=1080

mkdir -p "$OUTPUT_DIR" "$GIF_DIR"

detect_gpu_backend() {
    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q 'h264_nvenc' \
        && compgen -G "/dev/nvidia*" >/dev/null 2>&1; then
        echo "nvenc"
        return
    fi

    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q 'h264_vaapi'; then
        for dev in /dev/dri/renderD*; do
            [ -e "$dev" ] || continue
            if command -v vainfo >/dev/null 2>&1; then
                vainfo --display drm --device "$dev" >/dev/null 2>&1 || continue
            fi
            echo "vaapi:$dev"
            return
        done
    fi

    echo "cpu"
}

optimize_video() {
    local input="$1"
    local backend="$2"
    local tmp="${input%.mp4}.optimizing.mp4"

    case "$backend" in
        nvenc)
            ffmpeg -y -hwaccel cuda -hwaccel_output_format cuda -i "$input" \
                -vf "scale_cuda=w=min(${MAX_W}\,iw):h=min(${MAX_H}\,ih):force_original_aspect_ratio=decrease" \
                -c:v h264_nvenc -rc vbr -cq 23 -b:v 0 \
                -c:a copy "$tmp" 2>/dev/null
            ;;
        vaapi:*)
            local dev="${backend#vaapi:}"
            ffmpeg -y -hwaccel vaapi -hwaccel_output_format vaapi -vaapi_device "$dev" -i "$input" \
                -vf "scale_vaapi=w=min(${MAX_W}\,iw):h=min(${MAX_H}\,ih):force_original_aspect_ratio=decrease" \
                -c:v h264_vaapi -qp 24 \
                -c:a copy "$tmp" 2>/dev/null
            ;;
        cpu)
            ffmpeg -y -i "$input" \
                -vf "scale=w=min(${MAX_W}\,iw):h=min(${MAX_H}\,ih):force_original_aspect_ratio=decrease" \
                -c:v libx264 -crf 20 -preset medium \
                -c:a copy "$tmp" 2>/dev/null
            ;;
    esac

    if [ $? -eq 0 ] && [ -s "$tmp" ]; then
        mv "$tmp" "$input"
    else
        rm -f "$tmp"
        notify-send -u critical "Video optimization failed" "Keeping original file" \
            -a "Screen Recorder" -t 6000
    fi
}

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
        -i "video-x-generic" -a "Screen Recorder" -t 4000

    ffmpeg -i "$input" \
        -vf "fps=15,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -loop 0 -y "$output" 2>/dev/null

    if [ $? -eq 0 ]; then
        ACTION=$(notify-send \
            -A "open=Open GIF" -A "folder=View Folder" \
            "GIF saved" "${basename}.gif" \
            -i "image-gif" -a "Screen Recorder" -t 10000)
        case "$ACTION" in
            open)   xdg-open "$output" ;;
            folder) xdg-open "$GIF_DIR" ;;
        esac
    else
        notify-send -u critical "GIF conversion failed" "ffmpeg error" \
            -a "Screen Recorder" -t 6000
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
            -i "video-x-generic" -a "Screen Recorder" -t 8000
        exit 0
    fi

    read -r VIDW VIDH < <(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height \
        -of csv=s=x:p=0 "$LATEST" 2>/dev/null | tr 'x' ' ')

    if [ -n "$VIDW" ] && [ -n "$VIDH" ] \
        && { [ "$VIDW" -gt "$MAX_W" ] || [ "$VIDH" -gt "$MAX_H" ]; } 2>/dev/null; then
        BACKEND=$(detect_gpu_backend)
        case "$BACKEND" in
            nvenc)    BACKEND_LABEL="NVENC (NVIDIA)" ;;
            vaapi:*)  BACKEND_LABEL="VAAPI (${BACKEND#vaapi:})" ;;
            cpu)      BACKEND_LABEL="CPU (no GPU encoder found)" ;;
        esac
        notify-send "Processing recording…" "Downscaling to ${MAX_H}p using $BACKEND_LABEL" \
            -i "video-x-generic" -a "Screen Recorder" -t 4000
        optimize_video "$LATEST" "$BACKEND"
    fi

    DURATION=$(ffprobe -v error -select_streams v:0 \
        -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 \
        "$LATEST" 2>/dev/null | cut -d. -f1)

    MIDPOINT=$(( ${DURATION:-2} / 2 ))
    ffmpeg -ss "$MIDPOINT" -i "$LATEST" \
        -vframes 1 -q:v 2 -y "$THUMB" 2>/dev/null

    if [ -n "$DURATION" ] && [ "$DURATION" -lt 16 ] 2>/dev/null; then
        ACTION=$(notify-send \
            -A "open=Open" -A "gif=To GIF" \
            "Recording saved" "<img src=\"$THUMB\"/>Saved to $OUTPUT_DIR" \
            -i "video-x-generic" -a "Screen Recorder" -t 10000)
    else
        ACTION=$(notify-send \
            -A "open=Open" \
            "Recording saved" "<img src=\"$THUMB\"/>Saved to $OUTPUT_DIR" \
            -i "video-x-generic" -a "Screen Recorder" -t 10000)
    fi

    case "$ACTION" in
        open) xdg-open "$LATEST" ;;
        gif)  convert_to_gif "$LATEST" ;;
    esac
}

if [ -f "$PIDFILE" ]; then
    stop_recording
else
    [ -z "$1" ] && exit 1

    GEOMETRY="$1"
    AUDIO_DEVICE=$(get_audio_device)
    FILEPATH="$OUTPUT_DIR/recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    echo "$FILEPATH" > "$FILEPATH_FILE"

    if [[ "$GEOMETRY" =~ ^([0-9]+),([0-9]+)\ ([0-9]+x[0-9]+)$ ]]; then
        GSR_GEOMETRY="${BASH_REMATCH[3]}+${BASH_REMATCH[1]}+${BASH_REMATCH[2]}"
    else
        GSR_GEOMETRY="$GEOMETRY"
    fi

    GSR_OPTS=(
        -w region -region "$GSR_GEOMETRY"
        -k h264
        -q high
        -s 0x0
        -f 60
        -ac aac
        -o "$FILEPATH"
    )

    if [ -n "$AUDIO_DEVICE" ]; then
        setsid gpu-screen-recorder "${GSR_OPTS[@]}" -a "device:$AUDIO_DEVICE" </dev/null >/dev/null 2>&1 &
    else
        notify-send "Warning" "No active audio monitor found, recording without audio" \
            -i "dialog-warning" -a "Screen Recorder" -t 6000
        setsid gpu-screen-recorder "${GSR_OPTS[@]}" </dev/null >/dev/null 2>&1 &
    fi

    echo $! > "$PIDFILE"

    ( sleep $MAX_DURATION && \
      [ -f "$PIDFILE" ] && \
      notify-send "Recording limit reached" "Auto stopping at 5 minutes" \
          -u "critical" -a "Screen Recorder" -t 6000 && \
      stop_recording ) &
    echo $! > "$TIMERPID_FILE"

    notify-send "Recording started" "Recording region..." \
        -i "media-record" -a "Screen Recorder" -t 3000
fi