local apps = require("custom.actions.apps")
local display = require("custom.actions.display")
local floating = require("custom.actions.floating")
local layout = require("custom.actions.layout")

-- Binding helpers: rebind replaces defaults loaded by hyprland/keybinds.lua.
local function bind(key, action, description)
	if description then
		hl.bind(key, action, { description = description })
	else
		hl.bind(key, action)
	end
end

local function rebind(key, action, description)
	hl.unbind(key)
	bind(key, action, description)
end

local function rebind_cmd(key, command, description)
	rebind(key, hl.dsp.exec_cmd(command), description)
end

local function bind_cmd(key, command, description)
	bind(key, hl.dsp.exec_cmd(command), description)
end

local function bind_global(key, name, description)
	bind(key, hl.dsp.global(name), description)
end

-- Register a fullscreen kitty app with a matching window rule.
local function fullscreen_kitty_app(class, command, key)
	bind_cmd(key, string.format("kitty --class %s %s", class, command))
	hl.window_rule({ match = { class = class }, fullscreen = true })
end

-- =============================================================================
-- Keybinds: system / session
-- =============================================================================

bind_cmd("SUPER + SHIFT + Q", "pkill -9 -f $(hyprctl activewindow -j | jq -r .class)")
bind_global("CTRL + ALT + Backspace", "quickshell:sessionToggle")
bind_cmd("SUPER + ALT + L", "loginctl lock-session")
hl.unbind("SUPER + L")

-- =============================================================================
-- Keybinds: apps
-- =============================================================================

bind_cmd("SUPER + SHIFT + E", "[float; size 1300 800; center] dolphin")
rebind("SUPER + W", apps.focus_or_launch_firefox(false), "App: Browser")
rebind("SUPER + SHIFT + W", apps.focus_or_launch_firefox(true))
rebind(
	"SUPER + SHIFT + O",
	apps.focus_or_launch({
		["obsidian"] = true,
		["md.obsidian.obsidian"] = true,
	}, "obsidian"),
	"App: Obsidian"
)
rebind_cmd("SUPER + X", "kitty nvim")
rebind_cmd("SUPER + C", "papers", "App: Document Viewer")
rebind_cmd("SUPER + SHIFT + T", "[float; size 1300 800; center] kitty")
rebind_cmd("SUPER + Return", "[float; size 1300 800; center] kitty fish -c 'fastfetch; exec fish'")

-- Special workspace toggles
rebind(
	"SUPER + O",
	apps.toggle_special_app({
		workspace = "special:vesktop",
		command = "vesktop",
		class = "vesktop",
	}),
	"App: Vesktop"
)

rebind(
	"SUPER + A",
	apps.toggle_special_app({
		workspace = "special:spotify",
		command = "spotify-launcher",
		class = "spotify",
	}),
	"App: Spotify"
)

rebind("CTRL + SHIFT + Escape", apps.toggle_special_term("special:btop", "btop", "kitty btop"))

-- Fcitx5
bind_cmd("SUPER + Backslash", "~/.config/hypr/custom/scripts/togglefcitx5.sh", "App: Toggle fcitx5")

-- =============================================================================
-- Keybinds: shell
-- =============================================================================

bind_cmd("SUPER + ALT + D", "~/.config/hypr/custom/scripts/toggledock.sh", "Shell: Toggle dock")
bind_cmd("SUPER + ALT + K", "~/.config/hypr/custom/scripts/toggleclock.sh", "Shell: Toggle clock")
bind_global("SUPER + ALT + J", "quickshell:barToggle", "Shell: Toggle bar")

-- =============================================================================
-- Keybinds: scripts / maintenance
-- =============================================================================

bind_cmd("SUPER + U", "kitty ~/.config/hypr/custom/scripts/printdotscommits.sh", "Misc: Check dots-hyprland commits")
bind_cmd("SUPER + SHIFT + U", "kitty ~/.config/hypr/custom/scripts/updatedots.sh", "Misc: Update dots-hyprland")
bind_cmd("SUPER + Y", "kitty ~/.config/hypr/custom/scripts/archstatusprint.sh", "Misc: Check Archstatus")
bind_cmd("SUPER + SHIFT + Y", "kitty sh -c 'topgrade && cachy-update'", "Misc: Update system")

-- =============================================================================
-- Keybinds: misc
-- =============================================================================
-- Floating
rebind("SUPER + ALT + Space", floating.cycle_active)

-- Workspace gaps
rebind("SUPER + ALT + Equal", function()
	display.adjust_gaps_out(5)
end, "Misc: Increase gaps_out")

rebind("SUPER + ALT + Minus", function()
	display.adjust_gaps_out(-5)
end, "Misc: Decrease gaps_out")

rebind("SUPER + CTRL + Equal", function()
	display.adjust_gaps_in(1)
end, "Misc: Increase gaps_in")

bind("SUPER + CTRL + Minus", function()
	display.adjust_gaps_in(-1)
end, "Misc: Decrease gaps_in")

-- =============================================================================
-- Keybinds: layout cycling
-- =============================================================================

bind("SUPER + Z", function()
	layout.cycle({ "scrolling", "monocle" })
end, "Misc: !CYCLE LAYOUT")
bind("CTRL + SUPER + Z", function()
	layout.cycle({ "dwindle", "master" })
end, "Misc: !CYCLE LAYOUT (TILED)")

-- =============================================================================
-- Layout keybinds
-- =============================================================================
-- Shared keys: rebind removes the default first; later binds add layout-guarded
-- actions. Keep this order so one layout does not unbind another.
-- Dwindle
rebind("SUPER + J", layout.bind("dwindle", "togglesplit"))
rebind("SUPER + Semicolon", layout.bind("dwindle", "splitratio -0.1"))
rebind("SUPER + Apostrophe", layout.bind("dwindle", "splitratio +0.1"))

-- Master
bind("SUPER + J", layout.bind("master", "swapwithmaster"))
bind("SUPER + SHIFT + J", layout.bind("master", "addmaster"))
bind("SUPER + SHIFT + K", layout.bind("master", "removemaster"))
rebind("SUPER + Comma", layout.bind("master", "cyclenext noloop"))
rebind("SUPER + Period", layout.bind("master", "cycleprev noloop"))
bind("SUPER + SHIFT + Comma", layout.bind("master", "swapprev noloop"))
bind("SUPER + SHIFT + Period", layout.bind("master", "swapnext noloop"))
bind("SUPER + ALT + Comma", layout.bind("master", "rollprev"))
bind("SUPER + ALT + Period", layout.bind("master", "rollnext"))
bind("SUPER + Semicolon", layout.bind("master", "mfact -0.05"))
bind("SUPER + Apostrophe", layout.bind("master", "mfact +0.05"))
bind("SUPER + Space", layout.bind("master", "orientationcycle"), "Window: [m] Cycle orientation")

-- Monocle
bind("ALT + TAB", layout.bind("monocle", "cyclenext"))

-- Scrolling
bind("SUPER + Period", layout.bind("scrolling", "focus u"), "Window: [s] Move view (u)")
bind("SUPER + Comma", layout.bind("scrolling", "focus d"), "Window: [s] Move view (d)")
bind("SUPER + SHIFT + Period", layout.bind("scrolling", "consume_or_expel prev"))
bind("SUPER + SHIFT + Comma", layout.bind("scrolling", "consume_or_expel next"))
bind("SUPER + ALT + Comma", layout.bind("scrolling", "swapcol r"))
bind("SUPER + ALT + Period", layout.bind("scrolling", "swapcol l"))

bind("SUPER + Semicolon", layout.bind("scrolling", "colresize +0.1"))
bind("SUPER + Apostrophe", layout.bind("scrolling", "colresize -0.1"))

bind("SUPER + SHIFT + BracketLeft", hl.dsp.window.move({ direction = "l" }))
bind("SUPER + SHIFT + BracketRight", hl.dsp.window.move({ direction = "r" }))

rebind("SUPER + mouse_up", layout.bind("scrolling", "focus d"))
rebind("SUPER + mouse_down", layout.bind("scrolling", "focus u"))
rebind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
rebind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
rebind("SUPER + ALT + mouse_up", layout.bind("scrolling", "swapcol l"))
rebind("SUPER + ALT + mouse_down", layout.bind("scrolling", "swapcol r"))
rebind("CTRL + SUPER + mouse_up", layout.bind("scrolling", "colresize -0.1"))
rebind("CTRL + SUPER + mouse_down", layout.bind("scrolling", "colresize +0.1"))

-- =============================================================================
-- Fullscreen screensaver
-- =============================================================================

fullscreen_kitty_app(
	"neo",
	'neo -m "Those who worship the terminal never fear the system. They are the system." --defaultbg --speed=12 --density=10 --lingerms=1,1 --rippct=0',
	"SUPER + ALT + Backslash"
)
fullscreen_kitty_app("unimatrix", "unimatrix", "SUPER + SHIFT + Backslash")
fullscreen_kitty_app("vis", "vis", "CTRL + SUPER + Backslash")
fullscreen_kitty_app("terminal-rain", "terminal-rain", "CTRL + ALT + Backslash")
fullscreen_kitty_app("fetch", "fetch", "SUPER + ALT + Return")

-- Scrolling overview
bind("SUPER + Backspace", hl.plugin.scrolloverview.overview("toggle"))

-- =============================================================================
-- End4-pC
-- =============================================================================
hl.bind("SUPER + I", hl.dsp.global("quickshell:settingsToggle"), { description = "Toggle settings" })
rebind("SUPER + Tab", function()
	local active = hl.get_active_monitor()
	if not active then
		return
	end

	local target

	if active.name == "DP-2" then
		target = "HDMI-A-1"
	else
		target = "DP-2"
	end

	hl.dispatch(hl.dsp.focus({
		monitor = target,
	}))
end, "Monitor: Toggle focus")
