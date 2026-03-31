#!/bin/sh

QS_CONF="$HOME/.config/illogical-impulse/config.json"

# Get current dock enabled state (true/false)
CURRENT=$(jq -r '.dock.enable' "$QS_CONF")

if [ "$CURRENT" = "true" ]; then
  # Disable the dock
  jq '.dock.enable = false' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"
else
  # Enable the dock
  jq '.dock.enable = true' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"
fi
