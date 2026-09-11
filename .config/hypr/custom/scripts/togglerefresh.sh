#!/usr/bin/env bash
# Compatibility entry point; share the action used by the Lua keybind.
exec hyprctl eval 'require("custom.actions.display").toggle_refresh()'
