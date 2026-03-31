#!/usr/bin/env bash
set -euo pipefail

WS="special:1"
APP_CMD="vesktop"
CLASS_RE='vesktop'

# If already on special:1, do nothing.
if hyprctl -j monitors | jq -er '.[] | select(.focused) | .activeWorkspace.name=="'"$WS"'"' >/dev/null; then
  exit 0
fi

# Check for existing vesktop client.
read -r ADDR CURWS <<<"$(hyprctl -j clients |
  jq -r --arg re "$CLASS_RE" '
      .[] | select(.class|test($re; "i")) 
            | "\(.address) \(.workspace.name)"
                ' | head -n 1 || true)"

if [[ -z "${ADDR:-}" ]]; then
  # Not running: launch on special:1
  hyprctl dispatch exec "[workspace $WS] $APP_CMD"
else
  # Running: move to special:1 if needed
  if [[ "$CURWS" != "$WS" ]]; then
    hyprctl dispatch movetoworkspace "$WS,address:$ADDR"
  fi
fi

# Show special:1
hyprctl dispatch togglespecialworkspace 1
