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
	{
		match = {
			class = "vesktop",
		},
		workspace = "special:vesktop",
	},
	{
		match = {
			class = "spotify",
		},
		workspace = "special:spotify",
	},
}

for _, rule in ipairs(window_rules) do
	hl.window_rule(rule)
end

require("custom.actions.display").apply_gaps()
