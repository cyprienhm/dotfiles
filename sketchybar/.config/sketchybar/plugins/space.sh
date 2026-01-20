#!/bin/sh

# The $SELECTED variable is available for space components and indicates if
# the space invoking this script (with name: $NAME) is currently selected:
# https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item

source "$CONFIG_DIR/rose_pine_colors.sh"

if [[ "$SELECTED" == "true" ]]; then
    sketchybar --set "$NAME" label.color=$ROSE_PINE_LOVE
else
    sketchybar --set "$NAME" label.color=$ROSE_PINE_TEXT
fi

