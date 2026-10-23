#!/usr/bin/env bash
set -e

APPLET_ID="org.kde.plasma.superproductivity"
TARGET_DIR="$HOME/.local/share/plasma/plasmoids/$APPLET_ID"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/$APPLET_ID" && pwd)"

echo "Installing $APPLET_ID to $TARGET_DIR..."
mkdir -p "$HOME/.local/share/plasma/plasmoids"
ln -sfn "$SRC_DIR" "$TARGET_DIR"

echo "Reloading Plasmashell..."
systemctl --user restart plasma-plasmashell.service 2>/dev/null || true

echo "Done! Widget is registered. Add it to your panel via KDE Edit Mode."
