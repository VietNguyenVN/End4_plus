-- Configurable full-height window slots on a vertical tape.
-- Hyprland owns target order; new targets append and removals compact it.
local NAME = "lua:zscroll"
local rows = {}
local row_sizes = {}
local row_partitions = {}
local reordering = false
local M = {}
local pointer = require("custom.actions.pointer")
local options = { windows_per_row = 2, center_incomplete_rows = false }

function M.configure(settings)
	local count = settings.windows_per_row
	assert(type(count) == "number" and count >= 1 and count < math.huge and count == math.floor(count),
		"zscroll.windows_per_row must be a positive integer")
	assert(type(settings.center_incomplete_rows) == "boolean", "zscroll.center_incomplete_rows must be boolean")
	options = { windows_per_row = count, center_incomplete_rows = settings.center_incomplete_rows }
	row_sizes = {}
	row_partitions = {}
end

local function workspace_of(ctx)
	for _, target in ipairs(ctx.targets) do
		local win = target.window
		if win and win.workspace then
			return win.workspace
		end
	end
end

local function focused_index(ctx)
	local active = hl.get_active_window()
	if not active or active.floating then
		return nil
	end
	for i, target in ipairs(ctx.targets) do
		local win = target.window
		if win then
			if win.address == active.address then
				return i
			end
			-- A group is one layout target, even when another member has focus.
			if win.group then
				for _, member in ipairs(win.group.members or {}) do
					if member.address == active.address then
						return i
					end
				end
			end
		end
	end
end

local function full_width(target)
	local function tagged(win)
		local tags = win and win.tags or {}
		if type(tags) == "string" then
			for tag in tags:gmatch("[^,%s]+") do
				if tag == "zscroll-full" or tag == "zscroll-full*" then return true end
			end
		else
			for _, tag in ipairs(tags) do
				if tag == "zscroll-full" or tag == "zscroll-full*" then return true end
			end
		end
		return false
	end
	local win = target.window
	if tagged(win) then return true end
	if win and win.group then
		for _, member in ipairs(win.group.members or {}) do
			if tagged(member) then return true end
		end
	end
	return false
end

local function order_key(targets)
	local ids = {}
	for i, target in ipairs(targets) do
		local win = target.window
		ids[i] = tostring(win and (win.stable_id or win.address) or i) .. (full_width(target) and "!" or "")
	end
	return table.concat(ids, ":")
end

-- Preserve target order: a full-width target starts its own row, even if the
-- preceding row has an empty right slot. Pair ordinary targets after it anew.
local function pack(ctx)
	local slots, packed = {}, {}
	local workspace = workspace_of(ctx)
	local partition = workspace and row_partitions[workspace.id]
	if partition and partition.order == order_key(ctx.targets) then
		local index = 1
		for row, count in ipairs(partition.counts) do
			packed[row] = {}
			for column = 0, count - 1 do
				packed[row][column + 1] = index
				slots[index] = { row = row, column = column, full = full_width(ctx.targets[index]) }
				index = index + 1
			end
		end
		return slots, packed
	end
	if workspace then row_partitions[workspace.id] = nil end
	local open_row
	for i, target in ipairs(ctx.targets) do
		local full = full_width(target)
		if full or not open_row then
			packed[#packed + 1] = {}
			open_row = #packed
		end
		local members = packed[open_row]
		slots[i] = { row = open_row, column = #members, full = full }
		members[#members + 1] = i
		if full or #members == options.windows_per_row then open_row = nil end
	end
	return slots, packed
end

-- Keep keyboard width adjustments for an unchanged ordered row only.
local function sizes_for(ctx, packed, workspace)
	local old = row_sizes[workspace.id] or {}
	local current, result = {}, {}
	for row, members in ipairs(packed) do
		local ids = { tostring(options.windows_per_row) }
		for _, index in ipairs(members) do
			local win = ctx.targets[index].window
			ids[#ids + 1] = tostring(win and (win.stable_id or win.address) or index)
		end
		local key = table.concat(ids, ":")
		local sizes = old[key]
		if not sizes then
			sizes = {}
			for column = 1, options.windows_per_row do sizes[column] = 1 / options.windows_per_row end
		end
		current[key], result[row] = sizes, sizes
	end
	row_sizes[workspace.id] = current
	return result
end

local function recalculate(ctx)
	if reordering then return end
	local workspace = workspace_of(ctx)
	if not workspace or #ctx.targets == 0 then return end
	local slots, packed = pack(ctx)
	local sizes = sizes_for(ctx, packed, workspace)
	local i = focused_index(ctx)
	local row = i and slots[i].row or (rows[workspace.id] or 1)
	row = math.max(1, math.min(row, #packed))
	rows[workspace.id] = row
	local area = ctx.area
	for index, target in ipairs(ctx.targets) do
		local slot = slots[index]
		local fractions = sizes[slot.row]
		local start, occupied = 0, 0
		for column = 1, slot.column do start = start + fractions[column] end
		for column = 1, #packed[slot.row] do occupied = occupied + fractions[column] end
		local offset = options.center_incomplete_rows and not slot.full
			and math.floor((area.w - math.floor(area.w * occupied + 1e-7)) / 2) or 0
		local left = offset + math.floor(area.w * start + 1e-7)
		local right = offset + math.floor(area.w * (start + fractions[slot.column + 1]) + 1e-7)
		local width = slot.full and area.w or right - left
		target:place({
			x = area.x + left,
			y = area.y + (slot.row - row) * area.h,
			w = width,
			h = area.h,
		})
	end
end

local function destination(ctx, i, direction)
	local slots, packed = pack(ctx)
	local slot = slots[i]
	local members = packed[slot.row]
	if direction == "next" then
		return math.min(i + 1, #ctx.targets)
	elseif direction == "prev" then
		return math.max(i - 1, 1)
	elseif direction == "l" then
		return members[math.max(1, slot.column)]
	elseif direction == "r" then
		return members[math.min(#members, slot.column + 2)]
	elseif direction == "u" or direction == "d" then
		local adjacent = packed[slot.row + (direction == "u" and -1 or 1)]
		return adjacent and adjacent[math.min(#adjacent, slot.column + 1)] or i
	end
end

local function resize_focused(ctx, delta)
	local workspace, i = workspace_of(ctx), focused_index(ctx)
	if not workspace or not i or options.windows_per_row == 1 then return end
	local slots, packed = pack(ctx)
	local slot = slots[i]
	if slot.full then return end
	local sizes = sizes_for(ctx, packed, workspace)[slot.row]
	local column = slot.column + 1
	local minimum = math.min(120 / ctx.area.w, 1 / options.windows_per_row)
	local available = 0
	for j, size in ipairs(sizes) do
		if j ~= column then available = available + math.max(0, size - minimum) end
	end
	local change = math.max(minimum - sizes[column], math.min(delta, available))
	if math.abs(change) < 1e-10 then return end
	for j, size in ipairs(sizes) do
		if j ~= column then
			-- Growing borrows proportionally from slots with space to spare;
			-- shrinking returns space evenly, including unoccupied slots.
			local share = change > 0 and math.max(0, size - minimum) / available or 1 / (#sizes - 1)
			sizes[j] = size - change * share
		end
	end
	sizes[column] = sizes[column] + change
end

local function swap_row(ctx, direction)
	local workspace, i = workspace_of(ctx), focused_index(ctx)
	if not workspace or not i then return end
	local slots, packed = pack(ctx)
	local row = slots[i].row
	local adjacent = row + (direction == "u" and -1 or 1)
	if not packed[adjacent] then return end
	packed[row], packed[adjacent] = packed[adjacent], packed[row]
	local desired, counts, current = {}, {}, {}
	for index, target in ipairs(ctx.targets) do
		if not target.window then return end
		current[index] = target
	end
	for r, members in ipairs(packed) do
		counts[r] = #members
		for _, index in ipairs(members) do desired[#desired + 1] = ctx.targets[index] end
	end
	-- Native swaps recalculate synchronously. Wait until the whole permutation
	-- is finished so temporary pairings cannot discard the original row widths.
	reordering = true
	local ok, err = pcall(function()
		for index, target in ipairs(desired) do
			if current[index] ~= target then
				local other = index + 1
				while current[other] ~= target do other = other + 1 end
				hl.dispatch(hl.dsp.window.swap({ window = current[index].window, target = target.window }))
				current[index], current[other] = current[other], current[index]
			end
		end
	end)
	reordering = false
	if not ok then return "zscroll: row swap failed: " .. tostring(err) end
	-- Preserve partial rows too: moving a singleton ahead of a pair must not
	-- silently combine it with the first window of that pair.
	row_partitions[workspace.id] = { order = order_key(desired), counts = counts }
end

local function layout_msg(ctx, msg)
	if msg == "refresh" then
		return -- Hyprland calls recalculate after layout_msg returns.
	end
	local row_direction = msg:match("^swaprow ([ud])$")
	if row_direction then return swap_row(ctx, row_direction) end
	local resize_delta = msg:match("^resize ([+-]0%.05)$")
	if resize_delta then
		resize_focused(ctx, tonumber(resize_delta))
		return
	end
	local capacity_delta = msg:match("^capacity ([+-]1)$")
	if capacity_delta then
		M.configure({
			windows_per_row = math.max(1, options.windows_per_row + tonumber(capacity_delta)),
			center_incomplete_rows = options.center_incomplete_rows,
		})
		hl.notification.create({ text = "Z-scroll: " .. options.windows_per_row .. " windows per row", duration = 1500, icon = "info" })
		return
	end
	local action, direction = msg:match("^(%S+)%s+(%S+)$")
	if action ~= "focus" and action ~= "swap" then
		return "zscroll: expected focus/swap next|prev|l|r|u|d, or refresh"
	end
	local i = focused_index(ctx)
	if not i then
		return
	end
	local next_index = destination(ctx, i, direction)
	if not next_index then
		return "zscroll: unknown direction " .. tostring(direction)
	end
	if next_index == i then
		return
	end
	local win = ctx.targets[next_index].window
	if not win then
		return
	end
	if action == "swap" then
		-- Swap the actual layout targets, keeping native drag/swap order coherent.
		hl.dispatch(hl.dsp.window.swap({ target = win }))
	else
		hl.dispatch(hl.dsp.focus({ window = win }))
	end
end

hl.layout.register("zscroll", { recalculate = recalculate, layout_msg = layout_msg })

local function active_workspace()
	return hl.get_active_special_workspace() or hl.get_active_workspace()
end

-- Focus events can run during window creation. Defer until target insertion
-- finishes, and coalesce bursts to avoid re-entering the layout callback.
local pending_open
local refresh_timer
local function refresh()
	refresh_timer = nil
	local workspace = active_workspace()
	local win = pending_open
	pending_open = nil
	if win and win.mapped and not win.floating and win.workspace and workspace
		and win.workspace.id == workspace.id and workspace.tiled_layout == NAME then
		hl.dispatch(hl.dsp.focus({ window = win }))
	end
	if workspace and workspace.tiled_layout == NAME then
		hl.dispatch(hl.dsp.layout("refresh"))
	end
end

local function queue_refresh()
	-- One-shot timers are destroyed after firing in Hyprland 0.56; their
	-- handles cannot be rearmed. Create a fresh one for each event burst.
	if not refresh_timer then
		refresh_timer = hl.timer(refresh, { timeout = 1, type = "oneshot" })
	end
end

hl.on("window.open", function(win)
	local workspace = active_workspace()
	-- Do not steal focus for apps routed to a background/special workspace.
	if win and not win.floating and win.workspace and workspace
		and win.workspace.id == workspace.id and workspace.tiled_layout == NAME then
		pending_open = win
		queue_refresh()
	end
end)
hl.on("window.active", queue_refresh)
hl.on("workspace.active", queue_refresh)
hl.on("workspace.special_active", queue_refresh)
hl.on("window.fullscreen", queue_refresh)
hl.on("workspace.removed", function(workspace)
	-- The Lua wrapper may survive the removed workspace; its id is then nil.
	local id = workspace and workspace.id
	if id ~= nil then
		rows[id] = nil
		row_sizes[id] = nil
		row_partitions[id] = nil
	end
end)

function M.resize_focused(delta, fallback_direction)
	return function()
		local workspace, win = active_workspace(), hl.get_active_window()
		if workspace and workspace.tiled_layout == NAME and win and not win.floating then
			hl.dispatch(hl.dsp.layout("resize " .. delta))
		else
			hl.dispatch(hl.dsp.focus({ direction = fallback_direction }))
		end
	end
end

-- Used for shared directional bindings: other layouts keep their defaults.
function M.direction(action, direction)
	return function()
		local workspace = active_workspace()
		local active = hl.get_active_window()
		if workspace and workspace.tiled_layout == NAME and active and not active.floating then
			hl.dispatch(hl.dsp.layout(action .. " " .. direction))
		elseif action == "focus" then
			hl.dispatch(hl.dsp.focus({ direction = direction }))
		else
			hl.dispatch(hl.dsp.window.move({ direction = direction }))
		end
		if action == "focus" and workspace
			and (workspace.tiled_layout == NAME or workspace.tiled_layout == "scrolling") then
			pointer.center_after_navigation()
		end
	end
end

return M
