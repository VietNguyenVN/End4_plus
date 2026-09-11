-- Quickshell owns this JSON file; jq handles JSON while Lua handles the update.
local CONFIG_PATH = (os.getenv("HOME") or "") .. "/.config/illogical-impulse/config.json"

local function quote(value)
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function toggle_setting(path)
	return function()
		-- Match the old toggles: true becomes false; any other value becomes true.
		local filter = path .. " |= (. != true)"
		local process = assert(io.popen("jq " .. quote(filter) .. " " .. quote(CONFIG_PATH), "r"))
		local updated = process:read("*a")
		local ok = process:close()
		if not ok or not updated or updated == "" then
			hl.notification.create({ text = "Could not toggle " .. path .. ": check Quickshell config and jq", duration = 3000, icon = "info" })
			return
		end

		local temporary = CONFIG_PATH .. ".tmp"
		local file = assert(io.open(temporary, "w"))
		assert(file:write(updated))
		assert(file:close())
		assert(os.rename(temporary, CONFIG_PATH))
	end
end

return {
	toggle_dock = toggle_setting(".dock.enable"),
	toggle_clock = toggle_setting(".background.widgets.clock.enable"),
}
