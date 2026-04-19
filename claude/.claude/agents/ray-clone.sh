#!/usr/bin/env bash
set -euo pipefail

ALLOWED=(ray-2.55.0 ray-2.54.1 ray-2.54.0 ray-2.53.0)
tag="${1:?usage: ray-clone.sh <tag>}"

case " ${ALLOWED[*]} " in
  *" $tag "*) ;;
  *) echo "ray-clone: unsupported tag '$tag'. allowed: ${ALLOWED[*]}" >&2; exit 2 ;;
esac

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/ray-agent/versions"
dest="$cache_root/$tag"
docs="$dest/doc/source"

if [ -d "$docs" ] && [ -n "$(ls -A "$docs" 2>/dev/null)" ]; then
  echo "$docs"
  exit 0
fi

mkdir -p "$cache_root"
rm -rf "$dest"
git clone --depth 1 --branch "$tag" --filter=blob:none --sparse \
  https://github.com/ray-project/ray.git "$dest" >&2
git -C "$dest" sparse-checkout set doc/source >&2

echo "$docs"
