-- App actions return callbacks for key registration.
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

			hl.exec_cmd([[
		sh -c '
			read x y <<EOF
$(hyprctl activewindow -j | jq -r '"'"'[.at[0] + (.size[0] / 2 | floor), .at[1] + (.size[1] / 2 | floor)] | @tsv'"'"')
EOF
			hyprctl dispatch movecursor "$x" "$y"
		'
	]])
		end
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

-- Same thing, but separating firefox normal vs private sessions
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
	toggle_special_term = toggle_special_term,
	focus_or_launch = focus_or_launch,
	focus_or_launch_firefox = focus_or_launch_firefox,
}
