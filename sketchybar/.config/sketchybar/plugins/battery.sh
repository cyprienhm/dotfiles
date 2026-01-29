#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"
source "$CONFIG_DIR/rose_pine_colors.sh"

if [ "$PERCENTAGE" = "" ]; then
    exit 0
fi

case "${PERCENTAGE}" in
    9[0-9] | 100)
        ICON=""
        COLOR=0xff50fa7b
        ;;
    [6-8][0-9])
        ICON=""
        COLOR=0xff50fa7b
        ;;
    [3-5][0-9])
        ICON=""
        COLOR=0xffffb86c
        ;;
    [1-2][0-9])
        ICON=""
        COLOR=0xffff5555
        ;;
    *) ICON="" ;;
esac

if [[ "$CHARGING" != "" ]]; then
    ICON=""
    COLOR=0xff50fa7b
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.color=$ROSE_PINE_PINE label.color=$ROSE_PINE_PINE
