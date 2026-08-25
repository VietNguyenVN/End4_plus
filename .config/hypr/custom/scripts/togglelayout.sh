#!/bin/sh

CONF="$HOME/.config/hypr/custom/general.conf"
QS_CONF="$HOME/.config/illogical-impulse/config.json"

ANIM_LINE='animation = workspaces, 1, 7,menu_decel, slidevert'

CURRENT=$(hyprctl -j getoption general:layout | jq -r '.str')

if [ "$CURRENT" = "dwindle" ]; then
  # Add slidevert animation
  grep -Fxq "$ANIM_LINE" "$CONF" || echo "$ANIM_LINE" >>"$CONF"

  # Enable vertical parallax + scrolling overview
  jq '
    .background.parallax.vertical = true |
    .overview.style = "scrolling"
  ' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  hyprctl reload
  hyprctl keyword general:layout "scrolling"
  notify-send -a "Hyprland" "Layout changed" "📜 Scrolling layout"

else
  # Remove slidevert animation
  sed -i "\|$ANIM_LINE|d" "$CONF"

  # Disable vertical parallax + classic overview
  jq '
    .background.parallax.vertical = false |
    .overview.style = "classic"
  ' "$QS_CONF" >"$QS_CONF.tmp" &&
    mv "$QS_CONF.tmp" "$QS_CONF"

  hyprctl reload
  hyprctl keyword general:layout "dwindle"
  notify-send -a "Hyprland" "Layout changed" "🌀 Dwindle layout"
fi
