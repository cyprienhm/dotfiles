#!/bin/sh

PERCENTAGE="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%02.0f\n", 100-$5"%") }')%"

sketchybar --set "$NAME" label="${PERCENTAGE}" icon="󰘚" icon.color=0xffff79c6 icon.font="JetBrainsMonoNL Nerd Font:bold:17.0"
