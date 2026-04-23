#!/usr/bin/env bash
#
# Symlink tubesum.sh as `tubesum` into $INSTALL_DIR (default ~/.local/bin).
# Override the location with INSTALL_DIR=/some/bin ./install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/tubesum.sh"

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/tubesum"

if [[ ! -x "$SOURCE" ]]; then
  echo "Error: $SOURCE is missing or not executable." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"

if [[ -L "$TARGET" ]]; then
  existing="$(readlink "$TARGET")"
  if [[ "$existing" == "$SOURCE" ]]; then
    echo "Already installed: $TARGET -> $SOURCE"
    exit 0
  fi
  echo "Error: $TARGET is a symlink to $existing. Remove it or choose a different INSTALL_DIR." >&2
  exit 1
fi

if [[ -e "$TARGET" ]]; then
  echo "Error: $TARGET already exists and is not a symlink. Refusing to overwrite." >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
echo "Installed: $TARGET -> $SOURCE"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo
    echo "Warning: $INSTALL_DIR is not on your PATH."
    echo "Add this to your shell rc (e.g. ~/.zshrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac
