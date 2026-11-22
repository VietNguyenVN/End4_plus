-- App actions return callbacks for key registration.
local pointer = require("custom.actions.pointer")
local pending_overlay

local function toggle_special_app(opts)
	local workspace = opts.workspace
	local special_name = workspace:gsub("^special:", "")
	local class_fragment = opts.class:lower()

	local function matches(win)
		return win.class and win.class:lower():find(class_fragment, 1, true)
	end

	local function on_target_monitor()
		local monitor = hl.get_active_monitor()
		return monitor and monitor.name == opts.monitor
	end

	local function is_visible()
		local active_special = hl.get_active_special_workspace()
		return active_special and active_special.name == workspace
	end

	local function show_and_focus(win)
		if not win.workspace or win.workspace.name ~= workspace then
			hl.dispatch(hl.dsp.window.move({ window = win, workspace = workspace, follow = false }))
		end
		if not is_visible() then
			hl.dispatch(hl.dsp.workspace.toggle_special(special_name))
		end
		if on_target_monitor() and is_visible() then
			hl.dispatch(hl.dsp.focus({ window = win }))
			pointer.center_after_navigation()
		end
	end

	hl.on("window.open", function(win)
		local request = pending_overlay
		if not request or request.workspace ~= workspace or not matches(win) then return end
		pending_overlay = nil
		if on_target_monitor() then show_and_focus(win) end
	end)

	return function()
		local was_pending = pending_overlay and pending_overlay.workspace == workspace
		pending_overlay = nil
		hl.dispatch(hl.dsp.focus({ monitor = opts.monitor }))
		if not on_target_monitor() then return end
		if is_visible() then
			hl.dispatch(hl.dsp.workspace.toggle_special(special_name))
			return
		end
		if was_pending then return end

		for _, win in ipairs(hl.get_windows()) do
			if matches(win) then
				show_and_focus(win)
				return
			end
		end

		local request = { workspace = workspace }
		pending_overlay = request
		hl.timer(function()
			if pending_overlay == request then pending_overlay = nil end
		end, { timeout = 15000, type = "oneshot" })
		hl.exec_cmd(opts.command, { workspace = workspace, monitor = opts.monitor })
	end
end

-- Focus an existing matching app/window, switching to its workspace, or launch if none exists
local function focus_or_launch(classes, command)
	return function()
		for _, win in ipairs(hl.get_windows()) do
			local class = (win.class or ""):lower()
			if classes[class] then
				hl.dispatch(hl.dsp.focus({ window = win }))
				return
			end
		end

		hl.exec_cmd(command)
	end
end

-- Same thing, but separating zen-browser normal vs private sessions
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

-- Hyprland may reap the child before pipe:close(), so read pgrep's status
-- through stdout. Exit 1 means no match; other nonzero values mean failure.
local function toggle_fcitx5()
	local process = assert(io.popen('pgrep -x fcitx5 >/dev/null; printf "%s" "$?"', "r"))
	local status = tonumber(process:read("*a"))
	process:close()
	if status == 0 then
		hl.exec_cmd("pkill -x fcitx5")
	elseif status == 1 then
		hl.exec_cmd("fcitx5 -d")
	else
		hl.notification.create({ text = "Could not check fcitx5 process", duration = 3000, icon = "info" })
	end
end

return {
	toggle_fcitx5 = toggle_fcitx5,
	toggle_special_app = toggle_special_app,
	focus_or_launch = focus_or_launch,
	focus_or_launch_firefox = focus_or_launch_firefox,
}
