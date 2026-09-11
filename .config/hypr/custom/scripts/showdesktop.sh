#!/usr/bin/env bash
# Compatibility entry point; the keybind calls this Lua action directly.
exec hyprctl eval 'require("custom.actions.desktop").toggle()'
