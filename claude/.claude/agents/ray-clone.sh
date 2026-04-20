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

if [ -d "$dest/.git" ]; then
  echo "$dest"
  exit 0
fi

mkdir -p "$cache_root"
rm -rf "$dest"
git clone --depth 1 --branch "$tag" --filter=blob:none \
  https://github.com/ray-project/ray.git "$dest" >&2

echo "$dest"
