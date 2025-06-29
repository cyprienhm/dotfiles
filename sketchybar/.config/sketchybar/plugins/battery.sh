#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"
ICON_FONT="JetBrainsMonoNL Nerd Font:bold:14.0"

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
  ICON="󱋥"
  ICON="󰄌"
  ICON_FONT="JetBrainsMonoNL Nerd Font:bold:18.0"
  COLOR=0xff50fa7b
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.font="${ICON_FONT}" icon.color=${COLOR} label.color=${COLOR}
