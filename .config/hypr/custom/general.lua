-- Put general config stuff here

-- Monitor refresh rate
local refresh = 120

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

-- Layout & Misc
hl.config({
	general = {
		layout = "scrolling",
		-- border_size = 3,
		-- col = { active_border = "#acbdc7" },
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

-- hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menu_decel", style = "slidevert" })

-- Window animations
hl.curve("standard", {
	type = "bezier",
	points = { { 0.2, 0 }, { 0, 1 } },
})
hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 2,
	bezier = "emphasizedDecel",
})
hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 2,
	bezier = "emphasizedAccel",
})
hl.animation({
	leaf = "windowsMove",
	enabled = true,
	speed = 3.5,
	bezier = "standard",
})
hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 1.5,
	bezier = "emphasizedAccel",
})
