-- Overrides applied after hyprland/general.lua.

-- Z-scroll slots remain full-height; center any incomplete row as a group.
local zscroll_options = {
	windows_per_row = 2,
	center_incomplete_rows = true, -- also centers 2 windows in a 3-slot row, etc.
}
require("custom.layouts.zscroll").configure(zscroll_options)

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
	-- Appearance and input
	decoration = {
		blur = {
			xray = false,
		},
	},
	input = {
		follow_mouse = 0,
		kb_options = "fkeys:basic_13-24",
	},
})

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

-- Machine-specific overrides must be applied last.
require("custom.pc")
