#!/bin/bash
STATE_FILE="/tmp/hypr_gamemode_state"

hl_get_bool() { hyprctl -j getoption "$1" | jq -r 'if .bool then "true" else "false" end'; }
hl_get_int()  { hyprctl -j getoption "$1" | jq -r '.int'; }
hl_get_css()  { hyprctl -j getoption "$1" | jq -r '.css | split(" ")[0]'; }

if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    hyprctl eval "hl.config({
        animations = { enabled = $PREV_ANIMS },
        decoration = {
            shadow   = { enabled = $PREV_SHADOW },
            blur     = { enabled = $PREV_BLUR },
            rounding = $PREV_ROUNDING
        },
        general = {
            gaps_in       = $PREV_GAPS_IN,
            gaps_out      = $PREV_GAPS_OUT,
            border_size   = $PREV_BORDER,
            allow_tearing = $PREV_TEARING
        }
    })"
    rm "$STATE_FILE"
else
    PREV_ANIMS=$(hl_get_bool "animations.enabled")
    PREV_SHADOW=$(hl_get_bool "decoration.shadow.enabled")
    PREV_BLUR=$(hl_get_bool "decoration.blur.enabled")
    PREV_ROUNDING=$(hl_get_int "decoration.rounding")
    PREV_BORDER=$(hl_get_int "general.border_size")
    PREV_TEARING=$(hl_get_bool "general.allow_tearing")
    PREV_GAPS_IN=$(hl_get_css "general.gaps_in")
    PREV_GAPS_OUT=$(hl_get_css "general.gaps_out")

    printf '%s\n' \
        "PREV_ANIMS=$PREV_ANIMS" \
        "PREV_SHADOW=$PREV_SHADOW" \
        "PREV_BLUR=$PREV_BLUR" \
        "PREV_ROUNDING=$PREV_ROUNDING" \
        "PREV_BORDER=$PREV_BORDER" \
        "PREV_TEARING=$PREV_TEARING" \
        "PREV_GAPS_IN=$PREV_GAPS_IN" \
        "PREV_GAPS_OUT=$PREV_GAPS_OUT" \
        > "$STATE_FILE"

    hyprctl eval "hl.config({
        animations = { enabled = false },
        decoration = {
            shadow   = { enabled = false },
            blur     = { enabled = false },
            rounding = 0
        },
        general = {
            gaps_in       = 0,
            gaps_out      = 0,
            border_size   = 1,
            allow_tearing = true
        }
    })"
fi