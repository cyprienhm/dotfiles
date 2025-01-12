#!/bin/sh

CPU_USAGE=$(top -l 2 | grep -E "^CPU" | tail -1 | awk '{ printf "%02.0f\n", $3 + $5  }')

sketchybar --set "$NAME" label="${CPU_USAGE}%" icon="" icon.color=0xff8be9fd icon.font="JetBrainsMonoNL Nerd Font:bold:12.0"
