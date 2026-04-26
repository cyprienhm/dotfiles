#!/bin/bash
# Play a random sound from a category directory
# Usage: piped from claude code hooks via stdin JSON
# Categories: session-start, task-complete, task-error, input-required, resource-limit
set -uo pipefail

SOUNDS_DIR="$HOME/.claude/sounds/sc2_toss_probe/"
VOLUME=0.2

INPUT=$(cat)
EVENT=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null || echo "")
NTYPE=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('notification_type',''))" 2>/dev/null || echo "")
TOOL=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
ERROR=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error',''))" 2>/dev/null || echo "")

# Map event to category
case "$EVENT" in
    SessionStart)
        CAT="session-start" ;;
    Stop)
        CAT="task-complete" ;;
    PermissionRequest)
        CAT="input-required" ;;
    Notification)
        CAT="input-required" ;;
    PostToolUseFailure)
        if [ "$TOOL" = "Bash" ] && [ -n "$ERROR" ]; then
            CAT="task-error"
        else
            exit 0
        fi ;;
    PreCompact)
        CAT="resource-limit" ;;
    *) exit 0 ;;
esac

DIR="$SOUNDS_DIR/$CAT"
[ -d "$DIR" ] || exit 0

# Pick a random mp3/ogg/wav from the category
FILES=()
while IFS= read -r -d '' f; do
    FILES+=("$f")
done < <(find "$DIR" -maxdepth 1 \( -name '*.mp3' -o -name '*.ogg' -o -name '*.wav' \) -print0 2>/dev/null)

[ ${#FILES[@]} -eq 0 ] && exit 0

SOUND="${FILES[$((RANDOM % ${#FILES[@]}))]}"

# Kill any previous sound from us
PIDFILE="/tmp/.claude-sound.pid"
if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
fi

# Run afplay synchronously — the hook is async so Claude won't block.
# The script stays alive while afplay plays, preventing process tree reaping.
echo $$ > "$PIDFILE"
afplay -v "$VOLUME" "$SOUND" >/dev/null 2>&1
