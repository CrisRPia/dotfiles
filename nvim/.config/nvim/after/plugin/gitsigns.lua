require("gitsigns").setup({
    current_line_blame = true,
})
vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#56949f" })
vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ea9d34" })
vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#b4637a" })
