---@class showoff.config
---@field modes? string[]
---@field active? boolean
---@field window_width? integer
---@field max_tracked? integer
---@field compact_at? integer
---@field keys? table<string, string>
---@field exclude_keys? table<string, boolean>
---@field hide_on_ft? string[]
---@field hide_excluded_mode? boolean
---@field hide_after? integer
---@field exclude_mouse? boolean

---@class showoff.state
---@field active boolean
---@field input showoff.char[]
---@field win integer
---@field bufnr integer
---@field display_start integer
---@field timer uv_timer_t

---@class showoff.char
---@field char string
---@field width integer
---@field count integer
