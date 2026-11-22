-- Persist adjustable values as data, never by rewriting Lua source.
local M = {}
local SETTINGS_PATH = (os.getenv("HOME") or "") .. "/.config/hypr/custom/display-state.conf"
local SPECIAL_GAP_OFFSET = 20

function M.read_settings()
	local settings = { gaps_out = 5, gaps_in = 2 }
	local file = io.open(SETTINGS_PATH, "r")
	if not file then
		return settings
	end
	for line in file:lines() do
		local key, value = line:match("^(%w[%w_]*)=(%d+)$")
		value = tonumber(value)
		if settings[key] ~= nil and value then
			settings[key] = value
		end
	end
	file:close()
	return settings, true
end

local function save_settings(settings)
	local temporary = SETTINGS_PATH .. ".tmp"
	local file = assert(io.open(temporary, "w"))
	assert(file:write(string.format("gaps_out=%d\ngaps_in=%d\n", settings.gaps_out, settings.gaps_in)))
	assert(file:close())
	assert(os.rename(temporary, SETTINGS_PATH))
end

function M.apply_gaps(settings)
	settings = settings or M.read_settings()
	hl.workspace_rule({ workspace = "s[false]", gaps_out = settings.gaps_out, gaps_in = settings.gaps_in })
	hl.workspace_rule({ workspace = "s[true]", gaps_out = settings.gaps_out + SPECIAL_GAP_OFFSET, gaps_in = settings.gaps_in })
end

function M.restore_gaps()
	local settings, saved = M.read_settings()
	if saved then
		M.apply_gaps(settings)
	end
end

local function adjust_gaps(key, delta)
	local settings = M.read_settings()
	settings[key] = math.max(0, settings[key] + delta)
	save_settings(settings)
	M.apply_gaps(settings)
	hl.notification.create({
		text = string.format("gaps_out: %d/%d   gaps_in: %d", settings.gaps_out, settings.gaps_out + SPECIAL_GAP_OFFSET, settings.gaps_in),
		duration = 1500,
		icon = "info",
	})
end

function M.adjust_gaps_out(delta)
	adjust_gaps("gaps_out", delta)
end

function M.adjust_gaps_in(delta)
	adjust_gaps("gaps_in", delta)
end

return M
