-- =============================================================================
-- Environment
-- =============================================================================

local HOME = os.getenv("HOME") or ""
local XDG_RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR") or "/tmp"

local GENERAL_LUA = HOME .. "/.config/hypr/custom/general.lua"
local TMP_PREFIX = XDG_RUNTIME_DIR .. "/hypr_float_cycle_state-"

-- =============================================================================
-- Constants
-- =============================================================================

local FLOAT_SIZES = {
	{ 960, 600 }, -- small
	{ 1280, 800 }, -- medium
	{ 1600, 1000 }, -- large
}

-- Named special workspaces — single source of truth
local WS = {
	vesktop = "special:1",
	btop = "special:3",
	spotify = "special:4",
}

local COPILOT_KEY = "SUPER + SHIFT + F23"

-- =============================================================================
-- Utilities
-- =============================================================================

local function read_file(path)
	local f, err = io.open(path, "r")
	if not f then
		error(err)
	end
	local data = f:read("*a")
	f:close()
	return data
end

local function write_file(path, data)
	local f, err = io.open(path, "w")
	if not f then
		error(err)
	end
	f:write(data)
	f:close()
end

-- =============================================================================
-- Bind helpers
-- =============================================================================

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
	hl.unbind(key)
	bind(key, hl.dsp.exec_cmd(command), description)
end

local function bind_cmd(key, command, description)
	bind(key, hl.dsp.exec_cmd(command), description)
end

local function bind_global(key, name, description)
	bind(key, hl.dsp.global(name), description)
end

-- =============================================================================
-- Layout helpers
-- =============================================================================

local function current_layout_name()
	local current = hl.get_config("general.layout")
	return type(current) == "table" and current.name or current
end

local function layout_bind(layout_name, cmd)
	return function()
		if current_layout_name() ~= layout_name then
			return
		end
		hl.dispatch(hl.dsp.layout(cmd))
	end
end

local function cycle_layout(layouts)
	local current = current_layout_name()
	local next_index = 1

	for i, layout in ipairs(layouts) do
		if layout == current then
			next_index = (i % #layouts) + 1
			break
		end
	end

	hl.config({ general = { layout = layouts[next_index] } })
	hl.notification.create({
		text = "Layout: " .. layouts[next_index],
		duration = 2000,
		icon = "info",
	})
end

-- =============================================================================
-- Floating cycle helpers
-- =============================================================================

local function state_path_for(addr)
	return TMP_PREFIX .. addr:gsub("[^%w%-%._]", "_")
end

local function read_state(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return tonumber((data or ""):match("^(%d+)%s*$"))
end

local function write_state(path, idx)
	local f, err = io.open(path, "w")
	if not f then
		error(err)
	end
	f:write(tostring(idx))
	f:close()
end

local function cycle_floating_size(win)
	local state_file = state_path_for(win.address)

	if not win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
		local w, h = table.unpack(FLOAT_SIZES[1])
		hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false, window = win }))
		hl.dispatch(hl.dsp.window.center({ window = win }))
		write_state(state_file, 0)
		return
	end

	local next_index = (read_state(state_file) or 0) + 1

	if next_index >= #FLOAT_SIZES then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
		os.remove(state_file)
		return
	end

	local w, h = table.unpack(FLOAT_SIZES[next_index + 1])
	hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false, window = win }))
	hl.dispatch(hl.dsp.window.center({ window = win }))
	write_state(state_file, next_index)
end

-- =============================================================================
-- Special workspace / app helpers
-- =============================================================================

local function toggle_special_app(opts)
	local workspace = opts.workspace
	local class_re = opts.class:lower()

	return function()
		local active_ws = hl.get_active_workspace()
		if active_ws and active_ws.name == workspace then
			return
		end

		local target
		for _, win in ipairs(hl.get_windows()) do
			if win.class and win.class:lower():find(class_re, 1, true) then
				target = win
				break
			end
		end

		if not target then
			hl.exec_cmd(opts.command, { workspace = workspace })
		elseif not target.workspace or target.workspace.name ~= workspace then
			hl.dispatch(hl.dsp.focus({ window = target }))
			hl.dispatch(hl.dsp.move({ workspace = workspace }))
		end

		hl.dispatch(hl.dsp.workspace.toggle_special(workspace:gsub("^special:", "")))
	end
end

-- Spawn a fullscreen terminal app in a special workspace, toggling on repeat.
local function toggle_special_term(ws_full, title, command)
	return function()
		local ws_name = ws_full:gsub("^special:", "")

		local active_special = hl.get_active_special_workspace()
		if active_special and active_special.name == ws_full then
			hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
			return
		end

		local found = false
		for _, win in ipairs(hl.get_windows()) do
			if win.title == title then
				found = true
				break
			end
		end

		if not found then
			hl.exec_cmd(command, { workspace = ws_full })
		end

		hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
	end
end

-- Register a fullscreen kitty app with a matching window rule.
local function fullscreen_kitty_app(class, command, key)
	bind_cmd(key, string.format("kitty --class %s %s", class, command))
	hl.window_rule({ match = { class = class }, fullscreen = true })
end

-- =============================================================================
-- Refresh rate toggle
-- =============================================================================

local function toggle_refresh()
	local src = read_file(GENERAL_LUA)
	local current = tonumber(src:match("refresh%s*=%s*(%d+)"))

	local function notify(msg)
		hl.notification.create({
			text = "Hyprland Refresh Rate: " .. msg,
			duration = 3000,
			icon = "info",
		})
	end

	if not current then
		notify("Could not find refresh value")
		return
	end

	local next_rate = (current == 120) and 60 or 120
	local updated, count = src:gsub("refresh%s*=%s*%d+", "refresh = " .. next_rate, 1)

	if count == 0 then
		notify("Failed to update refresh value")
		return
	end

	write_file(GENERAL_LUA, updated)
	hl.exec_cmd("hyprctl reload")
	notify(string.format("eDP-1 switched to %dHz", next_rate))
end

-- =============================================================================
-- Input config
-- =============================================================================

hl.config({ input = { kb_options = "fkeys:basic_13-24" } })

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

bind_cmd("SUPER + SHIFT + E", "[float; size 960 600; center] dolphin")
bind_cmd("SUPER + SHIFT + W", "zen-browser --private-window")
bind_cmd("SUPER + SHIFT + O", "obsidian", "App: Obsidian")

rebind_cmd("SUPER + X", "kitty nvim")
rebind_cmd("SUPER + C", "papers", "App: Document Viewer")
rebind_cmd("SUPER + SHIFT + T", "[float; size 1300 800; center] kitty")
rebind_cmd("SUPER + Return", "[float; size 1300 800; center] kitty")

-- Special workspace toggles
rebind(
	"SUPER + O",
	toggle_special_app({
		workspace = WS.vesktop,
		command = "vesktop",
		class = "vesktop",
	}),
	"App: Vesktop"
)

rebind(
	"SUPER + A",
	toggle_special_app({
		workspace = WS.spotify,
		command = "spotify-launcher",
		class = "spotify",
	}),
	"App: Spotify"
)

rebind("CTRL + SHIFT + Escape", toggle_special_term(WS.btop, "btop", "kitty btop"))

-- Fcitx5
bind("SUPER + Backslash", function()
	local handle = io.popen("pgrep -x fcitx5 >/dev/null && echo 1 || echo 0")
	if not handle then
		return
	end
	local result = handle:read("*a")
	handle:close()
	hl.exec_cmd(result:match("1") and "pkill -x fcitx5" or "fcitx5 -d")
end, "App: Toggle fcitx5")

-- =============================================================================
-- Keybinds: shell
-- =============================================================================

bind_cmd("SUPER + ALT + D", "~/.config/hypr/custom/scripts/toggledock.sh", "Shell: Toggle dock")
bind_cmd("SUPER + ALT + K", "~/.config/hypr/custom/scripts/toggleclock.sh", "Shell: Toggle clock")
bind_global("SUPER + ALT + J", "quickshell:barToggle", "Shell: Toggle bar")
bind("SUPER + ALT + P", toggle_refresh, "Misc: Change refresh rate")

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
rebind("SUPER + ALT + Space", function()
	local win = hl.get_active_window()
	if not win or not win.address then
		return
	end
	cycle_floating_size(win)
end)

-- Adjust workspace gapps
local RULES_PATH = HOME .. "/.config/hypr/custom/rules.lua"
local GAP_OUT_STEP = 5
local GAP_IN_STEP = 1
local GAP_OUT_OFFSET = 20

local function current_workspace_gaps()
	local src = read_file(RULES_PATH)

	local gaps_out = tonumber(src:match('workspace%s*=%s*"s%[false%]".-gaps_out%s*=%s*(%d+)'))
	local gaps_in = tonumber(src:match('workspace%s*=%s*"s%[false%]".-gaps_in%s*=%s*(%d+)'))

	return gaps_out or 40, gaps_in or 8
end

local function set_workspace_gaps(base_out, base_in)
	local src = read_file(RULES_PATH)
	local second_out = base_out + GAP_OUT_OFFSET

	local out_count = 0
	src = src:gsub("gaps_out%s*=%s*%d+", function()
		out_count = out_count + 1
		if out_count == 1 then
			return "gaps_out = " .. base_out
		end
		return "gaps_out = " .. second_out
	end, 2)

	src = src:gsub("gaps_in%s*=%s*%d+", function()
		return "gaps_in = " .. base_in
	end, 2)

	write_file(RULES_PATH, src)
	hl.notification.create({
		text = string.format("gaps_out: %d/%d   gaps_in: %d", base_out, second_out, base_in),
		duration = 1500,
		icon = "info",
	})
end

local function adjust_gaps_out(delta)
	local base_out, base_in = current_workspace_gaps()
	set_workspace_gaps(math.max(0, base_out + delta), base_in)
end

local function adjust_gaps_in(delta)
	local base_out, base_in = current_workspace_gaps()
	set_workspace_gaps(base_out, math.max(0, base_in + delta))
end

rebind("SUPER + ALT + Equal", function()
	adjust_gaps_out(GAP_OUT_STEP)
end, "Misc: Increase gaps_out")

rebind("SUPER + ALT + Minus", function()
	adjust_gaps_out(-GAP_OUT_STEP)
end, "Misc: Decrease gaps_out")

rebind("SUPER + CTRL + Equal", function()
	adjust_gaps_in(GAP_IN_STEP)
end, "Misc: Increase gaps_in")

bind("SUPER + CTRL + Minus", function()
	adjust_gaps_in(-GAP_IN_STEP)
end, "Misc: Decrease gaps_in")

-- =============================================================================
-- Keybinds: layout cycling
-- =============================================================================

bind(COPILOT_KEY, function()
	cycle_layout({ "scrolling", "monocle" })
end, "Misc: !CYCLE LAYOUT")
bind("CTRL + " .. COPILOT_KEY, function()
	cycle_layout({ "dwindle", "master" })
end, "Misc: !CYCLE LAYOUT (TILED)")

-- =============================================================================
-- Keybinds: layout-specific — Dwindle
-- =============================================================================

rebind("SUPER + J", layout_bind("dwindle", "togglesplit"))
rebind("SUPER + Semicolon", layout_bind("dwindle", "splitratio -0.1"))
rebind("SUPER + Apostrophe", layout_bind("dwindle", "splitratio +0.1"))

-- =============================================================================
-- Keybinds: layout-specific — Master
-- =============================================================================

bind("SUPER + J", layout_bind("master", "swapwithmaster"))
bind("SUPER + SHIFT + J", layout_bind("master", "addmaster"))
bind("SUPER + SHIFT + K", layout_bind("master", "removemaster"))
rebind("SUPER + Comma", layout_bind("master", "cyclenext noloop"))
rebind("SUPER + Period", layout_bind("master", "cycleprev noloop"))
bind("SUPER + SHIFT + Comma", layout_bind("master", "swapprev noloop"))
bind("SUPER + SHIFT + Period", layout_bind("master", "swapnext noloop"))
bind("SUPER + ALT + Comma", layout_bind("master", "rollprev"))
bind("SUPER + ALT + Period", layout_bind("master", "rollnext"))
bind("SUPER + Semicolon", layout_bind("master", "mfact -0.05"))
bind("SUPER + Apostrophe", layout_bind("master", "mfact +0.05"))
bind("SUPER + Space", layout_bind("master", "orientationcycle"), "Window: [m] Cycle orientation")

-- =============================================================================
-- Keybinds: layout-specific — Monocle
-- =============================================================================

bind("ALT + TAB", layout_bind("monocle", "cyclenext"))

-- =============================================================================
-- Keybinds: layout-specific — Scrolling
-- =============================================================================

bind("SUPER + Period", layout_bind("scrolling", "focus u"), "Window: [s] Move view (u)")
bind("SUPER + Comma", layout_bind("scrolling", "focus d"), "Window: [s] Move view (d)")
bind("SUPER + SHIFT + Period", layout_bind("scrolling", "consume_or_expel prev"))
bind("SUPER + SHIFT + Comma", layout_bind("scrolling", "consume_or_expel next"))
bind("SUPER + ALT + Comma", layout_bind("scrolling", "swapcol r"))
bind("SUPER + ALT + Period", layout_bind("scrolling", "swapcol l"))

bind("SUPER + Semicolon", layout_bind("scrolling", "colresize +0.1"))
bind("SUPER + Apostrophe", layout_bind("scrolling", "colresize -0.1"))

bind("SUPER + SHIFT + BracketLeft", hl.dsp.window.move({ direction = "l" }))
bind("SUPER + SHIFT + BracketRight", hl.dsp.window.move({ direction = "r" }))

rebind("SUPER + mouse_up", layout_bind("scrolling", "focus d"))
rebind("SUPER + mouse_down", layout_bind("scrolling", "focus u"))
rebind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
rebind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
rebind("SUPER + ALT + mouse_up", layout_bind("scrolling", "swapcol l"))
rebind("SUPER + ALT + mouse_down", layout_bind("scrolling", "swapcol r"))
rebind("CTRL + SUPER + mouse_up", layout_bind("scrolling", "colresize -0.1"))
rebind("CTRL + SUPER + mouse_down", layout_bind("scrolling", "colresize +0.1"))

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
