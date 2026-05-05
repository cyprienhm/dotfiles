#!/bin/bash
set -e

sudo dnf install -y gcc

mkdir -p "$HOME/.local/bin"

curl -fsSL https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz \
    | tar -xz -C "$HOME/.local" --strip-components=1

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
. "$HOME/.cargo/env"

RG_VER="15.1.0"
curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C /tmp
mv "/tmp/ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" "$HOME/.local/bin/rg"
rm -rf "/tmp/ripgrep-${RG_VER}-x86_64-unknown-linux-musl"

