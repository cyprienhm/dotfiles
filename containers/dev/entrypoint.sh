#!/bin/bash
set -euo pipefail

# Existing home volumes retain their dotfiles and authentication across rebuilds.
if [[ ! -w /workspace || ! -w "$HOME" ]]; then
    echo 'Workspace and home must be writable by container UID 1000.' >&2
    exit 1
fi

exec "$@"
