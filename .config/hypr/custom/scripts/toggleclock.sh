#!/bin/sh

QS_CONF="$HOME/.config/illogical-impulse/config.json"

# Read current clock state
CURRENT=$(jq -r '.background.widgets.clock.enable' "$QS_CONF")

if [ "$CURRENT" = "true" ]; then
  # Disable clock
  jq '.background.widgets.clock.enable = false' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"
else
  # Enable clock
  jq '.background.widgets.clock.enable = true' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"
fi
