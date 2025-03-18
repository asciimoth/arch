local hotkeys_popup = require("awful.hotkeys_popup.widget")

local nnn_keys = {
    ["nnn: general"] = {{
        modifiers = {},
        keys = {
            ['?'] = "help",
            ['hjkl'] = "navigation",
            ['g, Ctrl+a'] = "to top",
            ['G, Ctrl+e'] = "to bottom",
            ['PageUp, Ctrl+u'] = "page up",
            ['PageDown, Ctrl+d'] = "page down",
            ['J'] = "jump to line by number",
            ['Esc x2, Ctrl+q'] = "escape",
        }
    }},
    ["nnn: contexts"] = {{
        modifiers = {},
        keys = {
            ['1 2 3 4'] = "change context",
            ['q'] = "close current context",
            ['Tab'] = "next context",
            ['Shift+Tab'] = "prev context",
        }
    }},
    -- TODO: Add more nn hotkeys
}

hotkeys_popup.add_hotkeys(nnn_keys)

return {}
