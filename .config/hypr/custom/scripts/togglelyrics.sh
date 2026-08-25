#!/bin/sh

QS_CONF="$HOME/.config/illogical-impulse/config.json"

CURRENT=$(jq -r '.bar.mediaPlayer.lyrics.enable' "$QS_CONF")

if [ "$CURRENT" = "true" ]; then
  jq '.bar.mediaPlayer.lyrics.enable = false' \
    "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  notify-send -a "QuickShell" "Media player" "❌ Lyrics disabled"
else
  jq '.bar.mediaPlayer.lyrics.enable = true' \
    "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  notify-send -a "QuickShell" "Media player" "🎵 Lyrics enabled"
fi
