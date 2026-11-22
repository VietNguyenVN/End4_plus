require("hyprland.variables")
require("custom.variables")

-- The keybinds are not here any more: end4pC owns them. They are one table (one bind per line) that you edit in Tools > Keybinds
-- (Super + /): add, change, disable or delete any of them, and search them. The table is hyprland/binds.default.tsv in the shell's
-- folder; your own copy is ~/.config/hypr/keybinds.tsv. Loaded by ~/.config/end4pC/hyprland/binds.lua (through end4pC.lua).
-- Binds written by hand in Lua still work: put them in custom/keybinds.lua.

--##! Virtual machines
-- A submap with no binds, so a virtual machine gets every key. SUPER + ALT + F1 enters and leaves it.
hl.define_submap("virtual-machine", function()
    hl.bind("SUPER + ALT + F1", function()
        local currentsubmap = hl.get_current_submap()
        if currentsubmap == "virtual-machine" then
            hl.dispatch(hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'") )
            hl.dispatch(hl.dsp.submap("reset") )
        elseif currentsubmap == "" then
            hl.dispatch(hl.dsp.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'") )
            hl.dispatch(hl.dsp.submap("virtual-machine") )
        end
    end, {submap_universal = true})
end)
