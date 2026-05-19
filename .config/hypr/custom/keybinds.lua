-- Functions
local HOME = os.getenv("HOME") or ""
local XDG_RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR") or "/tmp"

local GENERAL_LUA = HOME .. "/.config/hypr/custom/general.lua"
local TMP_PREFIX = XDG_RUNTIME_DIR .. "/hypr_float_cycle_state-"

local SIZES = {
	{ 960, 600 }, -- small
	{ 1280, 800 }, -- medium
	{ 1600, 1000 }, -- large
}

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

local function notify(msg)
	hl.exec_cmd(string.format('hyprctl notify 1 3000 "rgb(33ccff)" "Hyprland Refresh Rate: %s"', msg))
end

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

local function unbind(key)
	hl.unbind(key)
end

local function bind_cmd(key, command, description)
	bind(key, hl.dsp.exec_cmd(command), description)
end

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

	hl.config({
		general = {
			layout = layouts[next_index],
		},
	})

	local next_layout = layouts[next_index]

	hl.notification.create({
		text = "Layout: " .. next_layout,
		duration = 2000,
		icon = "info",
	})
end

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
	local addr = win.address
	local state_file = state_path_for(addr)

	if not win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))

		local w, h = table.unpack(SIZES[1])
		hl.dispatch(hl.dsp.window.resize({
			x = w,
			y = h,
			relative = false,
			window = win,
		}))
		hl.dispatch(hl.dsp.window.center({ window = win }))

		write_state(state_file, 0)
		return
	end

	local current_index = read_state(state_file) or 0
	local next_index = current_index + 1

	if next_index >= #SIZES then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
		os.remove(state_file)
		return
	end

	local w, h = table.unpack(SIZES[next_index + 1])
	hl.dispatch(hl.dsp.window.resize({
		x = w,
		y = h,
		relative = false,
		window = win,
	}))
	hl.dispatch(hl.dsp.window.center({ window = win }))

	write_state(state_file, next_index)
end

local function toggle_special_app(opts)
	local workspace = opts.workspace
	local app_cmd = opts.command
	local class_re = opts.class:lower()

	return function()
		local active_ws = hl.get_active_workspace()
		if active_ws and active_ws.name == workspace then
			return
		end

		local target = nil
		for _, win in ipairs(hl.get_windows()) do
			if win.class and win.class:lower():find(class_re, 1, true) then
				target = win
				break
			end
		end

		if not target then
			hl.exec_cmd(app_cmd, {
				workspace = workspace,
			})
		elseif not target.workspace or target.workspace.name ~= workspace then
			hl.dispatch(hl.dsp.focus({
				window = target,
			}))
			hl.dispatch(hl.dsp.move({
				workspace = workspace,
			}))
		end

		local ws_name = workspace:gsub("^special:", "")
		hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
	end
end

local function toggle_refresh()
	local src = read_file(GENERAL_LUA)

	local current = tonumber(src:match("refresh%s*=%s*(%d+)"))
	if not current then
		notify("Could not find refresh value")
		return
	end

	local next_rate = (current == 120) and 60 or 120
	local updated, n = src:gsub("refresh%s*=%s*%d+", "refresh = " .. next_rate, 1)
	if n == 0 then
		notify("Failed to update refresh value")
		return
	end

	write_file(GENERAL_LUA, updated)
	hl.exec_cmd("hyprctl reload")
	notify(string.format("eDP-1 switched to %dHz", next_rate))
end

-- Binds
bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("pkill -9 -f $(hyprctl activewindow -j | jq -r .class)"))
bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("[float; size 960 600; center] dolphin"))
bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("firefox --private-window"))

-- App toggles
rebind(
	"SUPER + O",
	toggle_special_app({
		workspace = "special:1",
		command = "vesktop",
		class = "vesktop",
	}),
	"App: Vesktop"
)

bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("obsidian"), "App: Obsidian")

rebind(
	"SUPER + A",
	toggle_special_app({
		workspace = "special:4",
		command = "spotify-launcher",
		class = "spotify",
	}),
	"App: Spotify"
)

rebind("SUPER + X", hl.dsp.exec_cmd("kitty nvim"))
rebind("SUPER + C", hl.dsp.exec_cmd("papers"), "App: Document Viewer")

-- Scripts
bind_cmd("SUPER + U", "kitty ~/.config/hypr/custom/scripts/printdotscommits.sh", "Misc: Check dots-hyprland commits")
bind_cmd("SUPER + SHIFT + U", "kitty ~/.config/hypr/custom/scripts/updatedots.sh", "Misc: Update dots-hyprland")
bind_cmd("SUPER + Y", "kitty ~/.config/hypr/custom/scripts/archstatusprint.sh", "Misc: Check Archstatus")
bind_cmd("SUPER + SHIFT + Y", "kitty ~/.config/hypr/custom/scripts/updatesystem.sh", "Misc: Update system")

-- Shell
bind_cmd("SUPER + ALT + D", "~/.config/hypr/custom/scripts/toggledock.sh", "Shell: Toggle dock")
bind("SUPER + ALT + P", toggle_refresh, "Misc: Change refresh rate")
bind_cmd("SUPER + ALT + K", "~/.config/hypr/custom/scripts/toggleclock.sh", "Shell: Toggle clock")
bind("SUPER + ALT + J", hl.dsp.global("quickshell:barToggle"), "Shell: Toggle bar")
bind_cmd("SUPER + ALT + L", "loginctl lock-session")
unbind("SUPER + L")

-- Special windows
rebind("CTRL + SHIFT + Escape", function()
	local WS_NAME = "3"
	local WS = "special:" .. WS_NAME
	local TITLE = "btop"

	local active_special = hl.get_active_special_workspace()
	if active_special and active_special.name == WS then
		hl.dispatch(hl.dsp.workspace.toggle_special(WS_NAME))
		return
	end

	local found = false
	for _, win in ipairs(hl.get_windows()) do
		if win.title == TITLE then
			found = true
			break
		end
	end

	if not found then
		hl.exec_cmd("kitty btop", { workspace = WS })
	end

	hl.dispatch(hl.dsp.workspace.toggle_special(WS_NAME))
end)

bind("CTRL + ALT + Backspace", hl.dsp.global("quickshell:sessionToggle"))
bind("SUPER + Backslash", function()
	local handle = io.popen("pgrep -x fcitx5 >/dev/null && echo 1 || echo 0")
	if not handle then
		return
	end

	local result = handle:read("*a")
	handle:close()

	if result:match("1") then
		hl.exec_cmd("pkill -x fcitx5")
	else
		hl.exec_cmd("fcitx5 -d")
	end
end, "App: Toggle fcitx5")

bind_cmd(
	"SUPER + ALT + Backslash",
	'kitty --class neo neo -m "Those who worship the terminal never fear the system. They are the system." --defaultbg --speed=12 --density=10 --lingerms=1,1 --rippct=0'
)

hl.window_rule({
	match = {
		class = "neo",
	},
	fullscreen = true,
})

bind_cmd("SUPER + SHIFT + Backslash", "kitty --class unimatrix unimatrix")
hl.window_rule({
	match = {
		class = "unimatrix",
	},
	fullscreen = true,
})

bind_cmd("CTRL + SUPER + Backslash", "kitty --class vis vis")
hl.window_rule({
	match = {
		class = "vis",
	},
	fullscreen = true,
})

-- Floating cycle
rebind("SUPER + ALT + Space", function()
	local win = hl.get_active_window()
	if not win or not win.address then
		return
	end

	cycle_floating_size(win)
end)

-- Input / layout cycling
hl.config({
	input = {
		kb_options = "fkeys:basic_13-24",
	},
})

local Copilot = "SUPER + SHIFT + F23"

bind(Copilot, function()
	cycle_layout({ "scrolling", "monocle" })
end, "Misc: !CYCLE LAYOUT")

bind("CTRL + " .. Copilot, function()
	cycle_layout({ "dwindle", "master" })
end, "Misc: !CYCLE LAYOUT (TILED)")

-- Layout-specific binds
-- Dwindle
rebind("SUPER + J", layout_bind("dwindle", "togglesplit"))
rebind("SUPER + Semicolon", layout_bind("dwindle", "splitratio -0.1"))
rebind("SUPER + Apostrophe", layout_bind("dwindle", "splitratio +0.1"))
-- Master
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

-- Monocle
bind("ALT + TAB", layout_bind("monocle", "cyclenext"))

-- Scrolling
bind("SUPER + Period", layout_bind("scrolling", "focus u"), "Window: [s] Move view (u)")
bind("SUPER + Comma", layout_bind("scrolling", "focus d"), "Window: [s] Move view (d)")
bind("SUPER + SHIFT + Period", layout_bind("scrolling", "colresize +0.1"))
bind("SUPER + SHIFT + Comma", layout_bind("scrolling", "colresize -0.1"))
bind("SUPER + ALT + Comma", layout_bind("scrolling", "swapcol r"))
bind("SUPER + ALT + Period", layout_bind("scrolling", "swapcol l"))

rebind("SUPER + mouse_up", layout_bind("scrolling", "focus d"))
rebind("SUPER + mouse_down", layout_bind("scrolling", "focus u"))
rebind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
rebind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
rebind("SUPER + ALT + mouse_up", layout_bind("scrolling", "swapcol l"))
rebind("SUPER + ALT + mouse_down", layout_bind("scrolling", "swapcol r"))
rebind("CTRL + SUPER + mouse_up", layout_bind("scrolling", "colresize -0.1"))
rebind("CTRL + SUPER + mouse_down", layout_bind("scrolling", "colresize +0.1"))
