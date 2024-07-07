-- @alias mode
-- @type string
-- @value "n"
-- @value "v"
-- @value "V"
-- @value ""
-- @value "i"

---@class mykey.config
---@field modes? string[]
---@field active? boolean
---@field max_tracked? integer
---@field compact_at? integer
---@field keys table<string, string>
---@field exclude table<string, boolean>

---@class mykey.state
---@field active boolean
---@field input mykey.char[]
---@field win integer
---@field bufnr integer
---@field display_start integer

---@class mykey.char
---@field char string
---@field width integer
---@field count integer
