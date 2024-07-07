local ns = vim.api.nvim_create_namespace("tigh-latte.mykey")
local M = {}

local unpack = table.unpack or unpack

---@type mykey.state
local state = {
	active = false,
	input = {},
	win = -1,
	bufnr = -1,
}

---@type mykey.config
local default_opts = {
	modes = {},
	active = false,
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
	exclude = {
		[":"] = true,
	},
	compact_at = 2,
}

---@param config mykey.config
local function init(config)
	state.active = config.active or false

	vim.on_key(function(_, typed)
		if not state.active then
			return
		end
		if typed == "" then
			return
		end
		if config.exclude[typed] then
			return
		end

		if #config.modes > 0 then
			local mode = vim.api.nvim_get_mode().mode
			if not vim.tbl_contains(config.modes, mode) then
				return
			end
		end

		local key = vim.fn.keytrans(typed)
		M.update_state(key, state, config)

		local line = M.transform(state, config)
		M.handler(line, state)
	end, ns)
end

---@param opts? mykey.config
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	vim.api.nvim_create_user_command("Showoff", M.toggle, {})
	init(opts)
end

function M.toggle()
	state.active = not state.active
	if state.active then
		state.bufnr = vim.api.nvim_create_buf(false, true)

		state.win = vim.api.nvim_open_win(0, false, {
			relative = "editor",
			width = 40,
			height = 3,
			row = vim.o.lines - vim.o.cmdheight - 1,
			col = vim.o.columns,
			anchor = "SE",
			focusable = false,
			style = "minimal",
			noautocmd = true,
		})
		vim.api.nvim_win_set_buf(state.win, state.bufnr)
	else
		vim.api.nvim_win_close(state.win, true)
		state.win = -1

		vim.api.nvim_buf_delete(state.bufnr, { force = true })
		state.bufnr = -1
	end
end

---update the state
---@param key string
---@param st mykey.state
---@param config mykey.config
function M.update_state(key, st, config)
	key = config.keys[string.upper(key)] or key
	if #st.input == 0 then
		table.insert(st.input, { char = key, count = 1 })
	else
		local last_input = st.input[#st.input]
		if key ~= last_input.char then
			table.insert(st.input, { char = key, count = 1 })
		else
			last_input.count = last_input.count + 1
		end
	end

	if #st.input > config.max_tracked then
		st.input = { unpack(st.input, #st.input - config.max_tracked + 1, #st.input) }
	end
end

---transform an input into a string
---@param st mykey.state
---@param config mykey.config
---@return string
local function smarter_transform(st, config)
	local cell_width = 0
	local len = 0

	local builder = {}
	for i = #st.input, 1, -1 do
		local input = st.input[i]
		local render = input.count < config.compact_at and string.rep or function(s, n, _)
			return s .. "x" .. n
		end
		table.insert(builder, 1, " ")
		table.insert(builder, 1, render(input.char, input.count, " "))
		cell_width = cell_width + 1 + vim.api.nvim_strwidth(builder[1])
		len = len + 1 + #builder[1]
		if cell_width <= 40 then
			st.display_start = len
		end
	end

	return table.concat(builder, "")
end

M.transform = smarter_transform

---Text handler
---@param line string the line to render
---@param st mykey.state the line to render
function M.handler(line, st)
	local to_print = line:sub(-st.display_start)
	to_print = string.rep(" ", 40 - st.display_start) .. to_print
	vim.api.nvim_buf_set_lines(st.bufnr, 1, 2, false, { to_print })
end

local augroup = vim.api.nvim_create_augroup("tigh-latte.mykey", { clear = true })
vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
	pattern = "*",
	callback = function()
		if not state.active then
			return
		end
		vim.api.nvim_win_close(state.win, { force = true })
		state.win = vim.api.nvim_open_win(0, false, {
			relative = "editor",
			width = 40,
			height = 3,
			row = vim.o.lines - vim.o.cmdheight - 1,
			col = vim.o.columns,
			anchor = "SE",
			focusable = false,
			style = "minimal",
			noautocmd = true,
		})
		vim.api.nvim_win_set_buf(state.win, state.bufnr)
	end,
})

return M
