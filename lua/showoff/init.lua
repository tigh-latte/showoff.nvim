local ns = vim.api.nvim_create_namespace("tigh-latte.showoff")
local unpack = table.unpack or unpack

local M = {
	---@type showoff.state
	state = {
		active = false,
		input = {},
		win = -1,
		bufnr = -1,
		augroup = -1,
		display_start = 0,
		cell_start = 0,
		timer = vim.uv.new_timer(),
	},

	---@type showoff.config
	config = {
		active = false,
		window = {
			enable = true,
			width = 35,
			height = 3,
		},
		input = {
			modes = {},
			max_tracked = 50,
			remap = {
				["<Space>"] = "␣",
				["<Left>"] = "",
				["<Right>"] = "",
				["<Up>"] = "",
				["<Down>"] = "",
				["<Esc>"] = "Esc",
				["<Tab>"] = "󰌒",
				["<CR>"] = "󰌑",
				["<F1>"] = "F1",
				["<F2>"] = "F2",
				["<F3>"] = "F3",
				["<F4>"] = "F4",
				["<F5>"] = "F5",
				["<F6>"] = "F6",
				["<F7>"] = "F7",
				["<F8>"] = "F8",
				["<F9>"] = "F9",
				["<F10>"] = "F10",
				["<F11>"] = "F11",
				["<F12>"] = "F12",
			},
			exclude_keys = {},
			exclude_fts = {},
			mouse = false,
			deduplicate_at = 4,
		},
		hide = {
			after = 3500,
			excluded = true,
		},
	},
}

local function open_window()
	if not M.config.window.enable then return end
	if M.state.bufnr > 0 or M.state.win > 0 then
		return
	end
	M.state.bufnr = vim.api.nvim_create_buf(false, true)
	M.state.win = vim.api.nvim_open_win(M.state.bufnr, false, {
		hide = #M.state.input == 0,
		relative = "editor",
		width = M.config.window.width,
		height = M.config.window.height,
		row = vim.o.lines - vim.o.cmdheight - 1,
		col = vim.o.columns,
		anchor = "SE",
		focusable = false,
		style = "minimal",
		noautocmd = true,
	})
end

--- decide whether or not to display
local function draw_window()
	if not M.config.window.enable then return end
	local display = #M.config.input.modes == 0 or vim.tbl_contains(M.config.input.modes, vim.api.nvim_get_mode().mode)
	display = display and
		(#M.config.input.exclude_fts == 0 or not vim.tbl_contains(M.config.input.exclude_fts, vim.bo.ft))

	if not pcall(vim.api.nvim_win_set_config, M.state.win, { hide = not display }) then
		M.state.bufnr = -1
		M.state.win = -1
		open_window()
		M.render()
	end
end


local function close_window()
	if not M.config.window.enable then return end
	if M.state.win > -1 then
		vim.api.nvim_win_close(M.state.win, true)
		M.state.win = -1
	end

	if M.state.bufnr > -1 then
		vim.api.nvim_buf_delete(M.state.bufnr, { force = true })
		M.state.bufnr = -1
	end
end


---@param config? showoff.config
function M.setup(config)
	config = config or {}

	local k = {}
	for _, ignore in ipairs(config.input.exclude_keys or {}) do
		k[ignore] = true
	end
	config.input.exclude_keys = k

	M.config = vim.tbl_deep_extend("force", M.config, config or {})

	M.config.handler = M.config.handler or M.display
	if not M.config.input.mouse then
		M.config.input.exclude_keys = vim.tbl_deep_extend("keep", M.config.input.exclude_keys, {
			["<MouseMove>"] = true,
			["<LeftMouse>"] = true,
			["<LeftRelease>"] = true,
			["<LeftDrag>"] = true,
			["<2-LeftMouse>"] = true,
			["<2-LeftRelease>"] = true,
			["<2-LeftDrag>"] = true,
			["<3-LeftMouse>"] = true,
			["<3-LeftRelease>"] = true,
			["<3-LeftDrag>"] = true,
			["<4-LeftMouse>"] = true,
			["<4-LeftRelease>"] = true,
			["<4-LeftDrag>"] = true,
			["<RightMouse>"] = true,
			["<RightRelease>"] = true,
			["<RightDrag>"] = true,
			["<2-RightMouse>"] = true,
			["<2-RightRelease>"] = true,
			["<2-RightDrag>"] = true,
			["<3-RightMouse>"] = true,
			["<3-RightRelease>"] = true,
			["<3-RightDrag>"] = true,
			["<4-RightMouse>"] = true,
			["<4-RightRelease>"] = true,
			["<4-RightDrag>"] = true,
			["<MiddleMouse>"] = true,
			["<MiddleRelease>"] = true,
			["<MiddleDrag>"] = true,
			["<2-MiddleMouse>"] = true,
			["<2-MiddleRelease>"] = true,
			["<2-MiddleDrag>"] = true,
			["<3-MiddleMouse>"] = true,
			["<3-MiddleRelease>"] = true,
			["<3-MiddleDrag>"] = true,
			["<4-MiddleMouse>"] = true,
			["<4-MiddleRelease>"] = true,
			["<4-MiddleDrag>"] = true,
			["<ScrollWheelUp>"] = true,
			["<ScrollWheelDown>"] = true,
		})
	end

	vim.api.nvim_create_user_command("Showoff", function() M.toggle() end, {})
	if M.config.active then
		vim.cmd.Showoff()
	end

	return M
end

---toggle showoff
function M.toggle()
	M.state.active = not M.state.active
	if M.state.active then
		vim.on_key(vim.schedule_wrap(function(_, typed)
			if not M.state.active then return end
			if typed == "" then return end
			typed = vim.fn.keytrans(typed)
			if M.config.input.exclude_keys[typed] then return end

			if #M.config.input.exclude_fts > 0 and vim.tbl_contains(M.config.input.exclude_fts, vim.bo.ft) then
				return
			end

			if #M.config.input.modes > 0 then
				local mode = vim.api.nvim_get_mode().mode
				if not vim.tbl_contains(M.config.input.modes, mode) then
					return
				end
			end

			draw_window()
			M.update_state(typed)
			M.render()
		end), ns)

		M.state.augroup = vim.api.nvim_create_augroup("tigh-latte.showoff", { clear = true })
		vim.api.nvim_create_autocmd("VimResized", {
			group = M.state.augroup,
			pattern = "*",
			callback = function()
				if not M.state.active then return end
				close_window()
				open_window()
				M.render()
			end,
		})

		if #M.config.input.modes > 0 and M.config.hide.excluded then
			vim.api.nvim_create_autocmd("ModeChanged", {
				group = M.state.augroup,
				pattern = "*",
				callback = vim.schedule_wrap(function()
					if not M.state.active then return end
					draw_window()
				end),
			})
		end

		if #M.config.input.exclude_fts > 0 and M.config.hide.excluded then
			vim.api.nvim_create_autocmd("BufEnter", {
				group = M.state.augroup,
				pattern = "*",
				callback = vim.schedule_wrap(function()
					if not M.state.active then return end
					draw_window()
				end),
			})
		end


		open_window()

		M.render()
	else
		vim.on_key(nil, ns)
		vim.api.nvim_del_augroup_by_id(M.state.augroup)

		close_window()

		M.state.input = {}
		M.state.display_start = 0
		M.state.cell_start = 0
		M.state.timer:stop()
	end
end

function M.render()
	M.config.handler(M.transform())
end

---update the state
---@param key string
function M.update_state(key)
	key = M.config.input.remap[key] or key
	if #M.state.input == 0 then
		table.insert(M.state.input, { char = key, count = 1 })
	else
		local last_input = M.state.input[#M.state.input]
		if key ~= last_input.char then
			table.insert(M.state.input, { char = key, count = 1 })
		else
			last_input.count = last_input.count + 1
		end
	end
	if #M.state.input > M.config.input.max_tracked then
		M.state.input = { unpack(M.state.input, #M.state.input - M.config.input.max_tracked + 1, #M.state.input) }
	end

	if M.config.window.enable and M.config.hide.after > 0 then
		M.state.timer:stop()
		M.state.timer:start(M.config.hide.after, 0, vim.schedule_wrap(function()
			M.state.timer:stop()
			if not M.state.active then return end
			if not M.state.win == -1 then return end

			vim.api.nvim_win_set_config(M.state.win, { hide = true })
		end))
	end
end

---transform an input into a string
---@return string
function M.transform()
	local cell_width = 0
	local len = 0

	local bldr = {}
	for i = #M.state.input, 1, -1 do
		local input = M.state.input[i]
		local render = input.count < M.config.input.deduplicate_at and string.rep or function(s, n, _)
			return table.concat({ s, "..x", n }, "")
		end
		table.insert(bldr, 1, " ")
		table.insert(bldr, 1, render(input.char, input.count, " "))
		cell_width = cell_width + 1 + vim.api.nvim_strwidth(bldr[1])
		len = len + 1 + #bldr[1]
		if cell_width <= M.config.window.width - 1 then
			M.state.display_start = len
			M.state.cell_start = cell_width
		end
	end

	return table.concat(bldr, "")
end

---Text handler
---@param line string the line to render
function M.display(line)
	if not M.config.window.enable then return end

	local output = line:sub(-M.state.display_start)
	local padding = string.rep(" ", M.config.window.width - M.state.cell_start)
	vim.api.nvim_buf_set_lines(M.state.bufnr, 1, 2, false, { padding .. output })
end

return M
