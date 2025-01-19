#!/bin/sh

PERCENTAGE="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f\n", 100-$5"%") }')%"
COLOR=0xffff79c6
sketchybar --set "$NAME" label="${PERCENTAGE}" icon="󰘚" icon.color=${COLOR} label.color=${COLOR} icon.font="JetBrainsMonoNL Nerd Font:bold:17.0"
