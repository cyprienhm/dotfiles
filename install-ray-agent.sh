#!/usr/bin/env bash
set -euo pipefail

RAW="https://raw.githubusercontent.com/cyprienhm/dotfiles/main"
DEST="$HOME/.claude/agents"

mkdir -p "$DEST"
curl -fsSL "$RAW/claude/.claude/agents/ray-agent.md" -o "$DEST/ray-agent.md"
curl -fsSL "$RAW/claude/.claude/agents/ray-clone.sh" -o "$DEST/ray-clone.sh"
chmod +x "$DEST/ray-clone.sh"

echo "installed ray-agent to $DEST"
