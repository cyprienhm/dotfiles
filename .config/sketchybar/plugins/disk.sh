#!/bin/sh

FREE=$(df -H | grep -E '^(/dev/disk3s5).' | awk '{ printf ("%s\n", $2) }')
# USED=$(df -H | grep -E '^(/dev/disk3s5).' | awk '{ printf ("%s\n", $3) }')
PERCENTAGE=$((100 - $(df -H | grep -E '^(/dev/disk3s5).' | awk '{ printf ("%s\n", $5) }' | grep -oE '\d*')))

ICON=""
COLOR=0xffffb86c

# case "${PERCENTAGE}" in
# [5-9][0-9] | 100)
#   COLOR=0xff36d1e2
#   ;;
# [1-4][0-9])
#   COLOR=0xfface236
#   ;;
# *)
#   COLOR=0xffe23636
#   ;;
# esac

sketchybar --set "$NAME" icon="$ICON" label="$PERCENTAGE% ($FREE)" icon.color=${COLOR} icon.font="JetBrainsMonoNL Nerd Font:bold:15.0"
