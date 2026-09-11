#!/usr/bin/env bash
# Compatibility entry point; share the per-window cycle used by the Lua keybind.
exec hyprctl eval 'require("custom.actions.floating").cycle_active()'
