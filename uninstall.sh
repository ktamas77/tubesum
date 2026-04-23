#!/usr/bin/env bash
#
# Remove the `tubesum` symlink from $INSTALL_DIR (default ~/.local/bin),
# but only if it points to this repo's tubesum.sh.
# Override the location with INSTALL_DIR=/some/bin ./uninstall.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/tubesum.sh"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/tubesum"

if [[ ! -L "$TARGET" ]]; then
  if [[ -e "$TARGET" ]]; then
    echo "Error: $TARGET exists but is not a symlink. Refusing to remove." >&2
    exit 1
  fi
  echo "Nothing to uninstall at $TARGET."
  exit 0
fi

link_dest="$(readlink "$TARGET")"
if [[ "$link_dest" != "$SOURCE" ]]; then
  echo "Error: $TARGET points to $link_dest, not this repo's tubesum.sh. Refusing to remove." >&2
  exit 1
fi

rm "$TARGET"
echo "Uninstalled: $TARGET"
