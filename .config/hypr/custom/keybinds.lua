local apps = require("custom.actions.apps")
local desktop = require("custom.actions.desktop")
local display = require("custom.actions.display")
local floating = require("custom.actions.floating")
local layout = require("custom.actions.layout")
local scrolling = require("custom.actions.scrolling")
local zscroll = require("custom.layouts.zscroll")

local COPILOT_KEY = "SUPER + SHIFT + F23"

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

local function bind_cmd(key, command, description)
	bind(key, hl.dsp.exec_cmd(command), description)
end

-- Register a fullscreen kitty app with a matching window rule.
local function fullscreen_kitty_app(class, command, key)
	bind_cmd(key, string.format("kitty --class %s %s", class, command))
	hl.window_rule({ match = { class = class }, fullscreen = true })
end

-- =============================================================================
-- Keybinds: system / session
-- =============================================================================

rebind("SUPER + ALT + H", desktop.toggle)

-- =============================================================================
-- Keybinds: apps
-- =============================================================================

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

-- Special workspace toggles
rebind(
	"SUPER + O",
	apps.toggle_special_app({
		workspace = "special:vesktop",
		monitor = "HDMI-A-1",
		command = "vesktop",
		class = "vesktop",
	}),
	"App: Vesktop"
)

rebind(
	"SUPER + A",
	apps.toggle_special_app({
		workspace = "special:spotify",
		monitor = "HDMI-A-1",
		command = "spotify-launcher",
		class = "spotify",
	}),
	"App: Spotify"
)

-- Fcitx5
bind("SUPER + Backslash", apps.toggle_fcitx5, "App: Toggle fcitx5")

-- Workspace scrolling: up goes left, down goes right.
rebind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
rebind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "r+1" }))

-- Number keys select a workspace within the active group of ten.
local number_keys = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
local keypad_keys = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
for i, keycode in ipairs(number_keys) do
	local function send_to_workspace()
		local active = hl.get_active_workspace()
		if not active or active.id < 1 then return end
		local target = math.floor((active.id - 1) / 10) * 10 + i
		hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
	end
	bind("SUPER + ALT + code:" .. keycode, send_to_workspace, "Window: Send to workspace " .. (i % 10))
	bind("SUPER + ALT + code:" .. keypad_keys[i], send_to_workspace)
end

-- =============================================================================
-- Keybinds: shell
-- =============================================================================


-- Keep the PC maintenance shortcuts on their original chords.

bind("SUPER + Tab", function()
	local monitor = hl.get_active_monitor()
	if monitor and (monitor.name == "DP-2" or monitor.name == "HDMI-A-1") then
		local target = monitor.name == "DP-2" and "HDMI-A-1" or "DP-2"
		hl.dispatch(hl.dsp.focus({ monitor = target }))
	end
end, "Monitor: Toggle focus")

-- =============================================================================
-- Keybinds: misc
-- =============================================================================
-- Toggle blur, dimming and transparency together.
local opaque_rule = hl.window_rule({
	name = "visual-effects-opaque",
	match = { class = ".*" },
	opacity = "1 override 1 override 1 override",
	force_rgbx = true,
})
opaque_rule:set_enabled(false)

rebind("SUPER + Z", function()
	local enabled = not hl.get_config("decoration.blur.enabled")
	opaque_rule:set_enabled(not enabled)
	hl.config({
		decoration = {
			blur = { enabled = enabled },
			dim_inactive = enabled,
		},
	})
	hl.notification.create({
		text = enabled and "Visual effects: ON" or "Visual effects: OFF",
		duration = 2000,
		icon = "info",
	})
end, "Misc: Toggle visual effects")

bind("SUPER + P", hl.dsp.window.pin(), "Window: Pin")

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

bind(COPILOT_KEY, function()
	layout.cycle({ "scrolling", "lua:zscroll" })
end, "Misc: !CYCLE LAYOUT")
bind("CTRL + " .. COPILOT_KEY, function()
	layout.cycle({ "dwindle", "master" })
end, "Misc: !CYCLE LAYOUT (TILED)")
bind("ALT + " .. COPILOT_KEY, function()
	layout.cycle({ "monocle" })
end, "Misc: !MONOCLE LAYOUT")

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
bind("SUPER + Space", layout.bind("master", "orientationcycle"))

-- Scrolling
bind("SUPER + Period", layout.bind("scrolling", "focus u"))
bind("SUPER + Comma", layout.bind("scrolling", "focus d"))
bind("SUPER + SHIFT + Period", layout.bind("scrolling", "consume_or_expel prev"))
bind("SUPER + SHIFT + Comma", layout.bind("scrolling", "consume_or_expel next"))
bind("SUPER + ALT + Comma", layout.bind("scrolling", "swapcol r"))
bind("SUPER + ALT + Period", layout.bind("scrolling", "swapcol l"))

bind("SUPER + Semicolon", layout.bind("scrolling", "colresize +0.1"))
bind("SUPER + Apostrophe", layout.bind("scrolling", "colresize -0.1"))

bind("SUPER + SHIFT + Semicolon", function()
	scrolling.resize(-50)
end)
bind("SUPER + SHIFT + Apostrophe", function()
	scrolling.resize(50)
end)

rebind("SUPER + mouse_up", layout.bind("scrolling", "focus u"))
rebind("SUPER + mouse_down", layout.bind("scrolling", "focus d"))
rebind("SUPER + ALT + mouse_up", layout.bind("scrolling", "swapcol l"))
rebind("SUPER + ALT + mouse_down", layout.bind("scrolling", "swapcol r"))
rebind("CTRL + SUPER + mouse_up", layout.bind("scrolling", "colresize -0.1"))
rebind("CTRL + SUPER + mouse_down", layout.bind("scrolling", "colresize +0.1"))

-- Z-scroll: row capacity, navigation, and swaps.
bind("SUPER + Semicolon", layout.bind("lua:zscroll", "capacity -1"))
bind("SUPER + Apostrophe", layout.bind("lua:zscroll", "capacity +1"))
bind("SUPER + Comma", layout.bind("lua:zscroll", "focus d"))
bind("SUPER + Period", layout.bind("lua:zscroll", "focus u"))
bind("SUPER + SHIFT + Comma", layout.bind("lua:zscroll", "swap next"))
bind("SUPER + SHIFT + Period", layout.bind("lua:zscroll", "swap prev"))
bind("SUPER + ALT + Comma", layout.bind("lua:zscroll", "swaprow d"))
bind("SUPER + ALT + Period", layout.bind("lua:zscroll", "swaprow u"))
bind("SUPER + mouse_up", layout.bind("lua:zscroll", "focus u"))
bind("SUPER + mouse_down", layout.bind("lua:zscroll", "focus d"))
bind("SUPER + ALT + mouse_up", layout.bind("lua:zscroll", "swap u"))
bind("SUPER + ALT + mouse_down", layout.bind("lua:zscroll", "swap d"))
for key, direction in pairs({ Left = "l", Right = "r", Up = "u", Down = "d", BracketLeft = "l", BracketRight = "r" }) do
	rebind("SUPER + " .. key, zscroll.direction("focus", direction))
	rebind("SUPER + SHIFT + " .. key, zscroll.direction("swap", direction))
end

-- Override bracket focus in zscroll; other layouts keep directional focus.
hl.unbind("SUPER + BracketLeft")
hl.unbind("SUPER + BracketRight")
hl.bind("SUPER + BracketLeft", zscroll.resize_focused("-0.05", "l"), { repeating = true })
hl.bind("SUPER + BracketRight", zscroll.resize_focused("+0.05", "r"), { repeating = true })

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
fullscreen_kitty_app("fetch", "fetch", "SUPER + ALT + Return")

-- Resolve optional plugin dispatchers at keypress time.
bind("SUPER + Backspace", function()
	local plugin = hl.plugin and hl.plugin.scrolloverview
	if plugin and type(plugin.overview) == "function" then
		plugin.overview("toggle")
	end
end, "Layout: Toggle scrolling overview")

bind("CTRL + SUPER + Z", function()
	layout.cycle({ "scrolling", "lua:zscroll", "monocle" })
end, "Layout: Cycle scrolling / zscroll / monocle")
bind("CTRL + SUPER + SHIFT + Z", function()
	layout.cycle({ "dwindle", "master" })
end, "Layout: Cycle dwindle / master")
