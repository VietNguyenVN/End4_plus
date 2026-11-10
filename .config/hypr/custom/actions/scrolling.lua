local M = {}

-- Native scrolling resizes against the previous window (or the next for the
-- first window). Resize the next window inversely to control the right edge.
function M.resize(delta, window)
	window = window or hl.get_active_window()
	local workspace = window and window.workspace
	if not workspace or workspace.tiled_layout ~= "scrolling" or window.floating
		or window.fullscreen ~= 0 then return end
	local data = window.layout
	if not data or data.name ~= "scrolling" or not data.column then return end
	local windows = data.column.windows
	if #windows < 2 then return end
	local index = data.index_in_column + 1
	local left, right = windows[index - 1], windows[index + 1]
	local share = left and right and delta / 2 or delta
	local function resize(target, amount)
		hl.dispatch(hl.dsp.window.resize({ x = amount, y = 0, relative = true, window = target }))
	end
	-- For direction = down, x changes only the size within the column.
	if left then resize(window, share) end
	if right then resize(right, -share) end
end

return M
