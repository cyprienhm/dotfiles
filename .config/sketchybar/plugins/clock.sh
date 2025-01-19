#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

COLOR=0xfff8f8f2
sketchybar --set "$NAME" label="$(date '+%Y-%m-%d %H:%M:%S')" icon.color=${COLOR} label.color=${COLOR}
