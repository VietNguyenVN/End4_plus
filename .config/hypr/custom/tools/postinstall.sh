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

# Optional machine-specific shell, configured by the Lua profile.
if [[ -n "${DOTS_SHELL_REPO:-}" && -n "${qsConfig:-}" ]]; then
  shell_dir="$HOME/.config/quickshell/$qsConfig"
  mkdir -p "$(dirname "$shell_dir")"
  if [[ ! -d "$shell_dir" ]]; then
    git clone "$DOTS_SHELL_REPO" "$shell_dir"
  fi
  killall qs 2>/dev/null || true
  qs -c "$qsConfig" >/dev/null 2>&1 &
  disown
fi
