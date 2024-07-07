---@class showoff.config
---@field active? boolean
---@field input? showoff.config.input
---@field hide? showoff.config.hide
---@field window? showoff.config.window

---@class showoff.config.input
---@field modes? string[]
---@field remap? table<string, string>
---@field max_tracked? integer
---@field exclude_keys? table<string, boolean>
---@field mouse? boolean
---@field exclude_fts? string[]
---@field deduplicate_at? integer

---@class showoff.config.hide
---@field excluded? boolean
---@field after? integer

---@class showoff.config.window
---@field enable? boolean
---@field width? integer
---@field height? integer

---@class showoff.state
---@field active boolean
---@field input showoff.state.input[]
---@field win integer
---@field bufnr integer
---@field display_start integer
---@field cell_start integer
---@field timer uv_timer_t

---@class showoff.state.input
---@field char string
---@field width integer
---@field count integer
