#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

source "$CONFIG_DIR/rose_pine_colors.sh"
if [ "$SENDER" = "volume_change" ]; then
    VOLUME="$INFO"

    case "$VOLUME" in
        [1-9] | [1-9][0-9] | 100)
            ICON="󰕾"
            ;;
        *) ICON="󰖁" ;;
    esac

    sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%" \
        icon.color=$ROSE_PINE_GOLD label.color=$ROSE_PINE_GOLD
fi
