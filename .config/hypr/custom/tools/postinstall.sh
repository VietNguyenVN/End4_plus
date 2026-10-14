#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"

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

echo "==> Post-install update completed."

# --- end4-pC reinstall --
cd ~/.config/quickshell/
git clone https://github.com/pctrade/end4-pC.git
killall qs 2>/dev/null
qs -c end4-pC >/dev/null 2>&1 &
disown
