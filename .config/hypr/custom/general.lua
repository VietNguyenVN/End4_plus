-- Put general config stuff here

hl.config({
	-- Scrolling
	general = {
		layout = "scrolling",
	},
	scrolling = {
		fullscreen_on_one_column = false,
		column_width = 1,
		-- explicit_column_widths = "0.5, 1.0",
		direction = "down",
	},
	-- Master
	master = {
		new_status = "inherit",
	},
	-- Misc
	decoration = {
		blur = {
			xray = false,
		},
	},
	input = {
		follow_mouse = 0,
	},
})

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", default = true })
end

for i = 11, 20 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", default = true })
end

-- hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menu_decel", style = "slidevert" })

-- Window animations
hl.curve("standard", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.2, bezier = "standard" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel" })

-- Scrollingoverview plugin
hl.config({
	plugin = {
		scrolloverview = {
			scale = 0.6, -- preferred overview scale
			workspace_gap = 60,
			layout = "horizontal", -- vertical or horizontal
			shadow = {
				enabled = false,
			},
		},
	},
})

hl.bind("SUPER + Backspace", hl.plugin.scrolloverview.overview("toggle"))
