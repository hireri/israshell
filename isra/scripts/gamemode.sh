#!/bin/bash

STATE_FILE="/tmp/hypr_gamemode_state"

if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    hyprctl --batch "\
        keyword animations:enabled $PREV_ANIMS; \
        keyword decoration:shadow:enabled $PREV_SHADOW; \
        keyword decoration:blur:enabled $PREV_BLUR; \
        keyword general:gaps_in $PREV_GAPS_IN; \
        keyword general:gaps_out $PREV_GAPS_OUT; \
        keyword general:border_size $PREV_BORDER; \
        keyword decoration:rounding $PREV_ROUNDING; \
        keyword general:allow_tearing $PREV_TEARING"
    rm "$STATE_FILE"
else
    PREV_ANIMS=$(hyprctl getoption animations:enabled -j | jq '.int')
    PREV_SHADOW=$(hyprctl getoption decoration:shadow:enabled -j | jq '.set')
    PREV_BLUR=$(hyprctl getoption decoration:blur:enabled -j | jq '.set')
    PREV_GAPS_IN=$(hyprctl getoption general:gaps_in -j | jq '.custom')
    PREV_GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq '.custom')
    PREV_BORDER=$(hyprctl getoption general:border_size -j | jq '.int')
    PREV_ROUNDING=$(hyprctl getoption decoration:rounding -j | jq '.int')
    PREV_TEARING=$(hyprctl getoption general:allow_tearing -j | jq '.int')

    printf '%s\n' \
        "PREV_ANIMS=$PREV_ANIMS" \
        "PREV_SHADOW=$PREV_SHADOW" \
        "PREV_BLUR=$PREV_BLUR" \
        "PREV_GAPS_IN=$PREV_GAPS_IN" \
        "PREV_GAPS_OUT=$PREV_GAPS_OUT" \
        "PREV_BORDER=$PREV_BORDER" \
        "PREV_ROUNDING=$PREV_ROUNDING" \
        "PREV_TEARING=$PREV_TEARING" \
        > "$STATE_FILE"

    hyprctl --batch "\
        keyword animations:enabled 0; \
        keyword decoration:shadow:enabled false; \
        keyword decoration:blur:enabled false; \
        keyword general:gaps_in 0; \
        keyword general:gaps_out 0; \
        keyword general:border_size 1; \
        keyword decoration:rounding 0; \
        keyword general:allow_tearing true"
fi
