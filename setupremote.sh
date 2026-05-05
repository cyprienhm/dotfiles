#!/bin/bash
set -e

REPO="https://github.com/cyprienhm/dotfiles.git"
TMP="/tmp/dotfiles"

rm -rf "$TMP"
git clone --depth 1 "$REPO" "$TMP"

cp "$TMP/vim/.vimrc" "$HOME/.vimrc"
cp "$TMP/tmux/.tmux.conf.remote" "$HOME/.tmux.conf"
if ! grep -qF "# >>> dotfiles bashrc >>>" "$HOME/.bashrc" 2>/dev/null; then
    cat "$TMP/bash/.bashrc.remote" >> "$HOME/.bashrc"
fi

rm -rf "$HOME/.config/nvim"
mkdir -p "$HOME/.config/nvim"
cp -r "$TMP/nvim/.config/nvim/." "$HOME/.config/nvim/"

rm -rf "$TMP"
