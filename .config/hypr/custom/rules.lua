local window_rules = {
	-- Keep restored app maximize requests from overriding the tiling layout.
	-- Hyprland's maximize binding and app fullscreen requests still work.
	{
		match = {
			class = ".*",
		},
		suppress_event = "maximize",
	},
	{
		match = {
			class = ".*",
		},
		opacity = "0.89 override 0.89 override",
	},
	{
		match = {
			class = ".*",
		},
		no_blur = false,
	},
	-- Keep Waydroid opaque and full-width in lua:zscroll.
	-- Apply after the global opacity and blur rules.
	{
		match = {
			class = "(?i)waydroid(\\..*)?",
		},
		tag = "zscroll-full",
		opacity = "1 override 1 override 1 override",
		no_blur = true,
	},
	{
		match = {
			class = "vesktop",
		},
		workspace = "special:vesktop",
		tag = "zscroll-full",
	},
	{
		match = {
			class = "spotify",
		},
		workspace = "special:spotify",
		tag = "zscroll-full",
	},
}

for _, rule in ipairs(window_rules) do
	hl.window_rule(rule)
end

require("custom.actions.display").apply_gaps()
