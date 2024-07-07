local ns = vim.api.nvim_create_namespace("tigh-latte.showoff")
local unpack = table.unpack or unpack

local M = {
	---@type showoff.state
	state = {
		active = false,
		input = {},
		win = -1,
		bufnr = -1,
		display_start = 0,
		timer = vim.uv.new_timer(),
	},

	---@type showoff.config
	config = {
		modes = {},
		hide_excluded_mode = false,
		active = false,
		window_width = 40,
		max_tracked = 50,
		keys = {
			["<SPACE>"] = "␣",
			["<LEFT>"] = "",
			["<RIGHT>"] = "",
			["<UP>"] = "",
			["<DOWN>"] = "",
			["<ESC>"] = "Esc",
			["<TAB>"] = "󰌒",
			["<CR>"] = "󰌑",
		},
		exclude_keys = {
			[":"] = true,
		},
		hide_on_ft = {},
		compact_at = 4,
		hide_after = 4000,
		exclude_mouse = true,
	},
}

---@param config? showoff.config
function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
	if M.config.exclude_mouse then
		M.config.exclude_keys = vim.tbl_deep_extend("keep", M.config.exclude_keys, {
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
		})
	end

	vim.api.nvim_create_user_command("Showoff", function() M.toggle() end, {})
	if M.config.active then
		vim.cmd.Showoff()
	end
end

---toggle showoff
function M.toggle()
	M.state.active = not M.state.active
	if M.state.active then
		vim.on_key(vim.schedule_wrap(function(_, typed)
			if not M.state.active then return end
			if typed == "" then return end
			typed = vim.fn.keytrans(typed)
			if M.config.exclude_keys[typed] then return end

			if #M.config.hide_on_ft > 0 and vim.tbl_contains(M.config.hide_on_ft, vim.bo.ft) then
				return
			end

			if #M.config.modes > 0 then
				local mode = vim.api.nvim_get_mode().mode
				if not vim.tbl_contains(M.config.modes, mode) then
					return
				end
			end

			vim.api.nvim_win_set_config(M.state.win, { hide = not M.decide_display() })
			M.update_state(typed)
			M.render()
		end), ns)

		local augroup = vim.api.nvim_create_augroup("tigh-latte.showoff", { clear = true })
		vim.api.nvim_create_autocmd("VimResized", {
			group = augroup,
			pattern = "*",
			callback = function()
				if not M.state.active then return end

				vim.api.nvim_win_close(M.state.win, true)
				M.state.win = vim.api.nvim_open_win(0, false, {
					relative = "editor",
					width = M.config.window_width,
					height = 3,
					row = vim.o.lines - vim.o.cmdheight - 1,
					col = vim.o.columns,
					anchor = "SE",
					focusable = false,
					style = "minimal",
					noautocmd = true,
				})
				vim.api.nvim_win_set_buf(M.state.win, M.state.bufnr)
			end,
		})

		if #M.config.modes > 0 and M.config.hide_excluded_mode then
			vim.api.nvim_create_autocmd("ModeChanged", {
				group = augroup,
				pattern = "*",
				callback = vim.schedule_wrap(function()
					if not M.state.active then return end

					local win_config = vim.api.nvim_win_get_config(M.state.win)
					win_config.hide = not M.decide_display()
					vim.api.nvim_win_set_config(M.state.win, win_config)
				end),
			})
		end

		if #M.config.hide_on_ft > 0 then
			vim.api.nvim_create_autocmd("BufEnter", {
				group = augroup,
				pattern = "*",
				callback = vim.schedule_wrap(function()
					if not M.state.active then return end

					local win_config = vim.api.nvim_win_get_config(M.state.win)
					win_config.hide = not M.decide_display()
					vim.api.nvim_win_set_config(M.state.win, win_config)
				end),
			})
		end


		M.state.bufnr = vim.api.nvim_create_buf(false, true)
		M.state.win = vim.api.nvim_open_win(0, false, {
			hide = #M.state.input == 0,
			relative = "editor",
			width = M.config.window_width,
			height = 3,
			row = vim.o.lines - vim.o.cmdheight - 1,
			col = vim.o.columns,
			anchor = "SE",
			focusable = false,
			style = "minimal",
			noautocmd = true,
		})
		vim.api.nvim_win_set_buf(M.state.win, M.state.bufnr)

		M.render()
	else
		vim.on_key(nil, ns)
		vim.api.nvim_del_augroup_by_name("tigh-latte.showoff")

		vim.api.nvim_win_close(M.state.win, true)
		M.state.win = -1

		vim.api.nvim_buf_delete(M.state.bufnr, { force = true })
		M.state.bufnr = -1

		M.state.input = {}
		M.state.display_start = 0
	end
end

function M.render()
	M.handler(M.transform())
end

---update the state
---@param key string
function M.update_state(key)
	key = M.config.keys[string.upper(key)] or key
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
	if #M.state.input > M.config.max_tracked then
		M.state.input = { unpack(M.state.input, #M.state.input - M.config.max_tracked + 1, #M.state.input) }
	end

	M.state.timer:stop()
	M.state.timer:start(M.config.hide_after, 0, vim.schedule_wrap(function()
		M.state.timer:stop()
		if not M.state.active then return end
		if not M.state.win == -1 then return end

		vim.api.nvim_win_set_config(M.state.win, { hide = true })
	end))
end

---transform an input into a string
---@return string
function M.transform()
	local cell_width = 0
	local len = 0

	local bldr = {}
	for i = #M.state.input, 1, -1 do
		local input = M.state.input[i]
		local render = input.count < M.config.compact_at and string.rep or function(s, n, _)
			return table.concat({ s, "..x", n }, "")
		end
		table.insert(bldr, 1, " ")
		table.insert(bldr, 1, render(input.char, input.count, " "))
		cell_width = cell_width + 1 + vim.api.nvim_strwidth(bldr[1])
		len = len + 1 + #bldr[1]
		if cell_width <= M.config.window_width then
			M.state.display_start = len
		end
	end

	return table.concat(bldr, "")
end

--- decide whether or not to display
---@return boolean
function M.decide_display()
	local display = #M.config.modes == 0 or vim.tbl_contains(M.config.modes, vim.api.nvim_get_mode().mode)
	display = display and (#M.config.hide_on_ft == 0 or not vim.tbl_contains(M.config.hide_on_ft, vim.bo.ft))
	return display
end

---Text handler
---@param line string the line to render
function M.handler(line)
	local to_print = line:sub(-M.state.display_start)
	to_print = string.rep(" ", M.config.window_width - M.state.display_start) .. to_print
	vim.api.nvim_buf_set_lines(M.state.bufnr, 1, 2, false, { to_print })
end

return M
