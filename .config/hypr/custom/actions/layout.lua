local function active_workspace()
	return hl.get_active_special_workspace() or hl.get_active_workspace()
end

local function layout_bind(layout_name, cmd)
	return function()
		local workspace = active_workspace()
		if not workspace or workspace.tiled_layout ~= layout_name then
			return
		end
		hl.dispatch(hl.dsp.layout(cmd))
	end
end

local function cycle_layout(layouts)
	local workspace = active_workspace()
	if not workspace or #layouts == 0 then
		return
	end

	-- Switching between cycle groups starts at the first layout in that group.
	local next_index = 1

	for i, layout in ipairs(layouts) do
		if layout == workspace.tiled_layout then
			next_index = (i % #layouts) + 1
			break
		end
	end

	hl.workspace_rule({
		workspace = tostring(workspace.special and workspace.name or workspace.id),
		layout = layouts[next_index],
	})
	hl.notification.create({
		text = "Layout: " .. layouts[next_index],
		duration = 2000,
		icon = "info",
	})
end

return { bind = layout_bind, cycle = cycle_layout }
