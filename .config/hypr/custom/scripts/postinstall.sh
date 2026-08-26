#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
FISH_CONFIG="$HOME/.config/fish/config.fish"
FISH_SOURCE_LINE='source ~/.config/fish/auto-Hypr.fish'

echo "==> Starting post-install updates..."

# --- Replace all .conf.new files with their base versions ---
echo "==> Checking for new config versions..."
find "$CONFIG_DIR" -type f -name "*.conf.new" | while read -r new; do
  base="${new%.new}"
  echo "→ Replacing $(basename "$base") with new version..."
  mv -f "$new" "$base"
done

# --- Clean up .conf.old files ---
echo "==> Cleaning up old config backups..."
find "$CONFIG_DIR" -type f -name "*.conf.old" -print -delete

# --- Ensure Fish auto-Hypr sourcing ---
echo "==> Ensuring Fish config sources auto-Hypr..."
mkdir -p "$(dirname "$FISH_CONFIG")"

if ! grep -qxF "$FISH_SOURCE_LINE" "$FISH_CONFIG" 2>/dev/null; then
  echo "$FISH_SOURCE_LINE" >>"$FISH_CONFIG"
  echo "→ Added source line to config.fish"
else
  echo "→ Fish config already up to date"
fi

echo "==> Post-install update completed."
