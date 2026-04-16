#!/bin/bash
set -e
[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
SCREENSHOT_EDITOR="${SCREENSHOT_EDITOR:-satty}"
mkdir -p "$OUTPUT_DIR" 2>/dev/null || {
	notify-send "Screenshot Error" "Cannot create directory: $OUTPUT_DIR" -u critical -t 3000
	exit 1
}
pkill slurp 2>/dev/null && exit 0
ARGS=()
for arg in "$@"; do
	if [[ $arg == --editor=* ]]; then
		SCREENSHOT_EDITOR="${arg#--editor=}"
	else
		ARGS+=("$arg")
	fi
done
set -- "${ARGS[@]}"
cleanup() {
	kill $HYPRPICKER_PID 2>/dev/null || true
	wait $HYPRPICKER_PID 2>/dev/null || true
}
trap cleanup EXIT
open_editor() {
    local filepath="$1"
    if [[ $SCREENSHOT_EDITOR == "satty" ]]; then
        satty --filename "$filepath" \
            --output-filename "$filepath" \
            --actions-on-enter save-to-clipboard \
            --save-after-copy \
            --early-exit \
            --copy-command 'wl-copy'
    else
        $SCREENSHOT_EDITOR "$filepath"
    fi
}
MODE="${1:-smart}"
PROCESSING="${2:-slurp}"
PAD=4
JQ_MONITOR_GEO='
  def format_geo:
    .x as $x | .y as $y |
    (.width / .scale | floor) as $w |
    (.height / .scale | floor) as $h |
    .transform as $t |
    if $t == 1 or $t == 3 then
      "\($x),\($y) \($h)x\($w)"
    else
      "\($x),\($y) \($w)x\($h)"
    end;
'
get_rectangles() {
	local monitor_json active_workspaces fullscreen_workspaces

	monitor_json=$(hyprctl monitors -j)
	active_workspaces=$(echo "$monitor_json" | jq -r '[.[] | .activeWorkspace.id]')
	fullscreen_workspaces=$(hyprctl workspaces -j | jq -r '[.[] | select(.hasfullscreen) | .id]')

	echo "$monitor_json" | jq -r "${JQ_MONITOR_GEO} .[] | format_geo"

	hyprctl clients -j | jq -r \
		--argjson aws "$active_workspaces" \
		--argjson fws "$fullscreen_workspaces" \
		--argjson pad "$PAD" \
		'.[] | select(
			([.workspace.id] | inside($aws)) and
			([.workspace.id] | inside($fws) | not)
		) | "\(.at[0] - $pad),\(.at[1] - $pad) \(.size[0] + $pad*2)x\(.size[1] + $pad*2)"'
}
start_hyprpicker() {
	hyprpicker -r -z >/dev/null 2>&1 &
	HYPRPICKER_PID=$!
	sleep 0.25
}
case "$MODE" in
region)
	start_hyprpicker
	SELECTION=$(slurp 2>/dev/null) || true
	;;
windows)
	RECTS=$(get_rectangles)
	start_hyprpicker
	SELECTION=$(echo "$RECTS" | slurp -r 2>/dev/null) || true
	;;
fullscreen)
	SELECTION=$(hyprctl monitors -j | jq -r "${JQ_MONITOR_GEO} .[] | select(.focused == true) | format_geo")
	;;
smart | *)
	RECTS=$(get_rectangles)
	start_hyprpicker
	SELECTION=$(echo "$RECTS" | slurp 2>/dev/null) || true
	if [[ $SELECTION =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
		if ((${BASH_REMATCH[3]} * ${BASH_REMATCH[4]} < 20)); then
			click_x="${BASH_REMATCH[1]}"
			click_y="${BASH_REMATCH[2]}"
			while IFS= read -r rect; do
				if [[ $rect =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
					rect_x="${BASH_REMATCH[1]}"
					rect_y="${BASH_REMATCH[2]}"
					rect_width="${BASH_REMATCH[3]}"
					rect_height="${BASH_REMATCH[4]}"
					if ((click_x >= rect_x && click_x < rect_x + rect_width && click_y >= rect_y && click_y < rect_y + rect_height)); then
						SELECTION="${rect_x},${rect_y} ${rect_width}x${rect_height}"
						break
					fi
				fi
			done <<<"$RECTS"
		fi
	fi
	;;
esac
[[ -z $SELECTION ]] && exit 0
FILENAME="screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
FILEPATH="$OUTPUT_DIR/$FILENAME"
if [[ $PROCESSING == "slurp" ]]; then
	grim -g "$SELECTION" "$FILEPATH" || exit 1
	wl-copy <"$FILEPATH"
	(
		ACTION=$(notify-send "Screenshot saved" \
			"<img src=\"$FILEPATH\"/>Copied to clipboard and saved to $OUTPUT_DIR" \
			-t 5000 \
			-i "camera-photo" \
			-a "Screenshot" \
			-A "default=Edit")
		[[ $ACTION == "default" ]] && open_editor "$FILEPATH"
	) &
else
	grim -g "$SELECTION" - | wl-copy
fi