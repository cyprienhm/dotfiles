sb_separator() {
    sepName="sep$RANDOM"
    sketchybar \
        --add item "$sepName" "$1" \
        --set "$sepName" \
        label="─────────" \
        padding_left="$2" \
        padding_right="$3" \
        icon.drawing=off \
        label.font.size=9.0
}

