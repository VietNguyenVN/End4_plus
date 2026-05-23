-- Put general config stuff here

local refresh = 60

local monitors = {
	{
		output = "eDP-1",
		mode = string.format("1920x1200@%d", refresh),
		position = "auto",
		scale = 1,
		transform = 0,
	},
	{
		output = "DP-1",
		mode = "1920x1200@60",
		position = "1920x0",
		scale = 1,
		mirror = "eDP-1",
	},
}

for _, monitor in ipairs(monitors) do
	hl.monitor(monitor)
end

hl.config({
	general = {
		layout = "scrolling",
		gaps_in = 8,
		-- col = { active_border = "#06a5db" },
	},
	decoration = {
		blur = {
			xray = false,
		},
	},
	input = {
		follow_mouse = 0,
	},
	scrolling = {
		fullscreen_on_one_column = false,
		column_width = 1,
		-- explicit_column_widths = "0.5, 1.0",
		direction = "down",
	},
	master = {
		new_status = "inherit",
	},
})

-- animation = workspaces, 1, 7, menu_decel, slidevert
