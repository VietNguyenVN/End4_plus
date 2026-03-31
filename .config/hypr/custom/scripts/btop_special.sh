#!/usr/bin/env bash
set -euo pipefail

WS="special:3"
TITLE="btop"

# If already on special:3, exit it.
if hyprctl -j monitors | jq -er '.[] | select(.focused) | .activeWorkspace.name=="'"$WS"'"' >/dev/null; then
  hyprctl dispatch togglespecialworkspace 3
  exit 0
fi

# If btop client not found, launch it on special:3.
if ! hyprctl -j clients | jq -er '.[] | select(.title=="'"$TITLE"'")' >/dev/null; then
  hyprctl dispatch exec "[workspace $WS] kitty --title $TITLE -1 fish -i -l -c btop"
fi

# Go to special:3.
hyprctl dispatch togglespecialworkspace 3
