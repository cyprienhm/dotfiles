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
  COLOR=0xff00ff00
  ;;
[6-8][0-9])
  ICON=""
  COLOR=0xffc6f50a
  ;;
[3-5][0-9])
  ICON=""
  COLOR=0xfffa8c05
  ;;
[1-2][0-9])
  ICON=""
  COLOR=0xffe23636
  ;;
*) ICON="" ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="󱋥"
  ICON_FONT="JetBrainsMonoNL Nerd Font:bold:18.0"
  COLOR=0xff00ff00
fi

# The item invoking this script (name $NAME) will get its icon and label
# updated with the current battery status
sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.font="${ICON_FONT}" icon.color=${COLOR}
