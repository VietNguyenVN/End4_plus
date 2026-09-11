-- App actions return callbacks for key registration.
local function toggle_special_app(opts)
	local workspace = opts.workspace
	local class_fragment = opts.class:lower()

	return function()
		local active_ws = hl.get_active_workspace()
		if active_ws and active_ws.name == workspace then
			return
		end

		local target
		for _, win in ipairs(hl.get_windows()) do
			if win.class and win.class:lower():find(class_fragment, 1, true) then
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

-- Same thing, but separating firefox-browser normal vs private sessions
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

return {
	toggle_special_app = toggle_special_app,
	toggle_special_term = toggle_special_term,
	focus_or_launch = focus_or_launch,
	focus_or_launch_firefox = focus_or_launch_firefox,
}
