local TMP_PREFIX = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr_float_cycle_v2-"

local FLOAT_SIZES = {
	{ 960, 600 }, -- small
	{ 1280, 800 }, -- medium
	{ 1600, 1000 }, -- large
}

local function state_path_for(addr)
	return TMP_PREFIX .. addr:gsub("[^%w%-%._]", "_")
end

local function read_state(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return tonumber((data or ""):match("^(%d+)%s*$"))
end

local function write_state(path, idx)
	local f, err = io.open(path, "w")
	if not f then
		error(err)
	end
	f:write(tostring(idx))
	f:close()
end

local function cycle_floating_size(win)
	local state_file = state_path_for(win.address)

	if not win.floating then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
		local w, h = table.unpack(FLOAT_SIZES[1])
		hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false, window = win }))
		hl.dispatch(hl.dsp.window.center({ window = win }))
		write_state(state_file, 1)
		return
	end

	local next_index = (read_state(state_file) or 1) + 1

	if next_index > #FLOAT_SIZES then
		hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
		os.remove(state_file)
		return
	end

	local w, h = table.unpack(FLOAT_SIZES[next_index])
	hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false, window = win }))
	hl.dispatch(hl.dsp.window.center({ window = win }))
	write_state(state_file, next_index)
end

local function cycle_active()
	local win = hl.get_active_window()
	if win and win.address then
		cycle_floating_size(win)
	end
end

return { cycle_active = cycle_active }
