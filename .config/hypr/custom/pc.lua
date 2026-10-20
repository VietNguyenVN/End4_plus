-- PC-specific Hyprland overrides. Loaded only by custom/general.lua.
-- Load shared bindings/rules first; the upstream loader's later require calls
-- reuse Lua's module cache instead of overwriting these overrides.
require("custom.rules")
require("custom.keybinds")

hl.env("qsConfig", "end4-pC")
hl.env("QSG_RHI_BACKEND", "opengl")
hl.env("QSG_RENDER_LOOP", "threaded")
hl.env("DOTS_COMMIT_OWNER", "pctrade")
hl.env("DOTS_COMMIT_REPO", "end4-pC")
hl.env("DOTS_SHELL_REPO", "https://github.com/pctrade/end4-pC.git")

for i = 1, 20 do
    hl.workspace_rule({ workspace = tostring(i), monitor = i <= 10 and "DP-2" or "HDMI-A-1", default = true })
end

hl.window_rule({
    match = { title = "^(illogical-impulse Settings)$" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { title = "^(illogical-impulse Settings)$" },
    size = { "(monitor_w*0.50)", "(monitor_h*0.50)" },
})

local function rebind(key, action, description)
    hl.unbind(key)
    hl.bind(key, action, { description = description })
end

local function toggle_special_app(opts)
	local workspace = opts.workspace
	local special_name = workspace:gsub("^special:", "")
	local class_re = opts.class:lower()
	local monitor = opts.monitor or "HDMI-A-1"

	return function()
		-- Make HDMI-A-1 the active monitor first.
		hl.dispatch(hl.dsp.focus({
			monitor = monitor,
		}))

		-- If this special workspace is currently visible on the
		-- now-focused monitor, simply hide it.
		local active_special = hl.get_active_special_workspace()
		if active_special and active_special.name == workspace then
			hl.dispatch(hl.dsp.workspace.toggle_special(special_name))
			return
		end

		local target

		for _, win in ipairs(hl.get_windows()) do
			if win.class and win.class:lower():find(class_re, 1, true) then
				target = win
				break
			end
		end

		if target then
			-- Ensure existing window belongs to its special workspace.
			if not target.workspace or target.workspace.name ~= workspace then
				hl.dispatch(hl.dsp.window.move({
					window = target,
					workspace = workspace,
				}))
			end
		else
			-- Launch it directly into the special workspace.
			hl.exec_cmd(opts.command, {
				workspace = workspace,
				monitor = monitor,
			})
		end

		-- Show overlay on HDMI-A-1.
		hl.dispatch(hl.dsp.workspace.toggle_special(special_name))

		-- Find/focus the app.
		for _, win in ipairs(hl.get_windows()) do
			if win.class and win.class:lower():find(class_re, 1, true) then
				target = win
				break
			end
		end

		if target then
			hl.dispatch(hl.dsp.focus({
				window = target,
			}))

			require("custom.actions.pointer").center_after_navigation()
		end
	end
end

local function focus_or_launch_firefox(private)
	return function()
		for _, win in ipairs(hl.get_windows()) do
			local class = (win.class or ""):lower()
			local title = (win.title or ""):lower()
			local is_firefox = class == "firefox"
			local is_private = title:find("private browsing", 1, true) ~= nil

			if is_firefox and is_private == private then
				hl.dispatch(hl.dsp.focus({ window = win }))
				return
			end
		end

		hl.exec_cmd(private and "firefox --private-window" or "firefox --new-window")
	end
end


rebind("SUPER + W", focus_or_launch_firefox(false), "App: Browser")
rebind("SUPER + SHIFT + W", focus_or_launch_firefox(true), "App: Private browser")
rebind("SUPER + O", toggle_special_app({ workspace = "special:vesktop", command = "vesktop", class = "vesktop" }), "App: Vesktop")
rebind("SUPER + A", toggle_special_app({ workspace = "special:spotify", command = "spotify-launcher", class = "spotify" }), "App: Spotify")
-- Preserve main's Codex and ChatGPT shortcuts; give Papers its own shortcut.
rebind("SUPER + ALT + C", hl.dsp.exec_cmd("chatgpt"), "App: ChatGPT")
rebind("SUPER + ALT + P", hl.dsp.exec_cmd("papers"), "App: Document Viewer")
rebind("SUPER + I", hl.dsp.global("quickshell:settingsToggle"), "Shell: Toggle settings")
rebind("SUPER + Tab", function()
    local active = hl.get_active_monitor()
    if active then
        hl.dispatch(hl.dsp.focus({ monitor = active.name == "DP-2" and "HDMI-A-1" or "DP-2" }))
    end
end, "Monitor: Toggle focus")

-- PC keyboards need not have the laptop's Copilot/F23 key.
-- Keep Super+Z for main's visual-effects toggle and retain all F23 bindings.
local layout = require("custom.actions.layout")
rebind("CTRL + SUPER + Z", function()
    layout.cycle({ "scrolling", "lua:zscroll", "monocle" })
end, "Layout: Cycle scrolling / zscroll / monocle")
rebind("CTRL + SUPER + SHIFT + Z", function()
    layout.cycle({ "dwindle", "master" })
end, "Layout: Cycle dwindle / master")
rebind("SUPER + U", hl.dsp.exec_cmd("kitty ~/.config/hypr/custom/tools/printdotscommits.sh"), "Misc: Check end4-pC commits")
