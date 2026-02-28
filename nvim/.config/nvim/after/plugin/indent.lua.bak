local highlight = {
    "RainbowBlue",
}

local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#315A8A" })
end)

require("ibl").setup({
    scope = {
        enabled = true,
        show_exact_scope = true,
        highlight = highlight,
    },
})
