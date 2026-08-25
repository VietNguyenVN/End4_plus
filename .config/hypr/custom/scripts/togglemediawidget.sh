#!/bin/sh

QS_CONF="$HOME/.config/illogical-impulse/config.json"

CURRENT=$(jq -r '.background.widgets.media.enable' "$QS_CONF")

if [ "$CURRENT" = "true" ]; then
  jq '.background.widgets.media.enable = false' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  notify-send -a "QuickShell" "Media widget" "❌ Disabled"
else
  jq '.background.widgets.media.enable = true' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  notify-send -a "QuickShell" "Media widget" "🎵 Enabled"
fi
