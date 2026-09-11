-- Hidden workspace membership is the state: no address lists or temporary files.
local M = {}
local PREFIX = "special:show-desktop-"

function M.toggle()
	local workspace = hl.get_active_workspace()
	if not workspace then
		return
	end

	local hidden_name = PREFIX .. tostring(workspace.id)
	local windows = hl.get_windows()
	local restoring = false
	for _, win in ipairs(windows) do
		if win.workspace and win.workspace.name == hidden_name then
			restoring = true
			break
		end
	end

	-- Reveal the regular workspace even when a scratchpad is open above it.
	local special = hl.get_active_special_workspace()
	if special then
		hl.dispatch(hl.dsp.workspace.toggle_special(special.name:gsub("^special:", "")))
	end

	-- Snapshot the targets before moving: dispatching changes workspace membership.
	local targets = {}
	for _, win in ipairs(windows) do
		if win.workspace and not win.pinned then
			local is_hidden = win.workspace.name == hidden_name
			local is_current = win.workspace.id == workspace.id
			if (restoring and is_hidden) or (not restoring and is_current) then
				targets[#targets + 1] = win
			end
		end
	end

	for _, win in ipairs(targets) do
		hl.dispatch(hl.dsp.window.move({
			window = win,
			workspace = restoring and workspace or hidden_name,
			follow = false,
		}))
	end
end

return M
