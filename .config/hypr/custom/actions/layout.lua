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

return { bind = layout_bind, cycle = cycle_layout }
