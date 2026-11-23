-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Environment variables --
require("hyprland/env")
require("custom/env")

-- Defaults --
require("hyprland/execs")
require("hyprland/general")
require("hyprland/rules")
require("hyprland/colors")
require("hyprland/keybinds")

-- Custom --
require("custom/general")
require("custom/rules")
require("custom/keybinds")

-- end4pC shell: layer rules and possible keybinds --
-- The file lives in the shell's folder. If it is missing or has an error, the rest of this config still loads.
do
    local ok, err = pcall(dofile, os.getenv("HOME") .. "/.config/end4pC/hyprland/end4pC.lua")
    if not ok then print("end4pC: " .. tostring(err)) end
end

-- nwg-displays support: re-add the files if it updates later
-- require("workspaces")
require("monitors")

-- Shell overrides --
require("hyprland/shellOverrides/main")
require("custom/animations")
