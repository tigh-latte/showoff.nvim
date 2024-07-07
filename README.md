## Showoff

Just me having a go at writing a neovim plugin.

There is no reason to use this over [Screenkey](https://github.com/NStefan002/screenkey.nvim).

### Features

1. Whitelist modes. So, for example, don't display input when typing in insert of command mode.
1. Exclude filetypes.
1. Allows for you to override `display` function, just incase you want to send your output somewhere other than neovim.

### Installation

Using [lazy](https://github.com/folke/lazy.nvim.git):

```lua
{
    "github.com/tigh-latte/showoff.nvim",
    tag = "0.x",

    config = function()
        require("showoff").setup({})
    end,
}
```

### Options

```lua
{
    active = false, -- Enable at startup.
    window = { -- Window options
        enable = true, -- Enable to floating window. This should be set to false if you override showoff.display(string)
        width = 35,
        height = 3,
    },
    input = { -- Input options
        modes = {}, -- Whitelist modes to track keys. Leaving empty will register input from all modes.
        max_tracked = 50, -- maximum historical non-sequential keystrokes to track. This should be larger than `window.width`.
        remap = { -- remap neovim input keys before being displayed.
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
        exclude_keys = {}, -- table<string, boolean> of keys to exclude.
        exclude_fts = {}, -- list of filetypes to exclude
        mouse = false, -- display mouse clicks.
        deduplicate_at = 4, -- when to deduplicate consecutive keystrokes (j j j j -> j..x4)
    },
    hide = { -- When to hide the input window.
        after = 4000, -- how long to display the window for after the last accepted keypress. Set to 0 to disable hiding.
        excluded = true, -- hide the input window while in an excluded context (e.g., excluded filetype or mode).
    },
}
```

### Overriding `display(string)`

If you just want to use this as an engine for turning key presses into a formatted string, but you want that string to be displayed somewhere else, you can do as follows:

```lua
local showoff = require("showoff").setup({
    window = { enable = false },
})
showoff.display = function(line)
    -- Do whatever you want with line.
end
```

If you want to instead keep your input going to the floating window, and wish to add extra functionality:
```lua
local showoff = require("showoff").setup({})
local display = showoff.display
showoff.display = function(line)
    display(line)
    -- Do whatever else you want with line.
end
```
