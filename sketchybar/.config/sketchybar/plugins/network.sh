#!/bin/bash

source "$CONFIG_DIR/rose_pine_colors.sh"
INTERFACE=$(route -n get default 2>/dev/null | grep 'interface:' | awk '{print $2}')

if [ -n "$INTERFACE" ]; then
    IP=$(ifconfig "$INTERFACE" | grep "inet " | awk '{print $2}')
fi

sketchybar --set "$NAME" label="$IP"
