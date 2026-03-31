#!/usr/bin/env bash
set -euo pipefail

WS="special:4"
CLASS_RE='spotify'

APP_CMD="spotify-launcher"

# If already on special:4, do nothing.
if hyprctl -j monitors | jq -er '.[] | select(.focused) | .activeWorkspace.name=="'"$WS"'"' >/dev/null; then
  exit 0
fi

# Check for existing Spotify client.
read -r ADDR CURWS <<<"$(hyprctl -j clients |
  jq -r --arg re "$CLASS_RE" '
      .[] | select(.class|test($re; "i"))
                  | "\(.address) \(.workspace.name)"
                                  ' | head -n 1 || true)"

if [[ -z "${ADDR:-}" ]]; then
  # Not running: launch on special:4.
  hyprctl dispatch exec "[workspace $WS] $APP_CMD"
else
  # Running: move to special:4 if needed.
  if [[ "$CURWS" != "$WS" ]]; then
    hyprctl dispatch movetoworkspace "$WS,address:$ADDR"
  fi
fi

# Show special:4.
hyprctl dispatch togglespecialworkspace 4
