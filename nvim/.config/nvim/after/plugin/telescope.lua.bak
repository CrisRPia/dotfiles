local builtin = require("telescope.builtin")
local telescope = require("telescope")

vim.keymap.set("n", "<leader>pt", builtin.lsp_workspace_symbols)
vim.keymap.set("n", "<leader>pf", builtin.find_files)
vim.keymap.set("n", "grr", builtin.lsp_references)
vim.keymap.set("n", "<leader>gf", builtin.git_files)
vim.keymap.set("n", "<leader>ps", builtin.live_grep)
vim.keymap.set("n", "<leader>pd", builtin.diagnostics)

vim.keymap.set("n", "<leader>tr", builtin.resume)
vim.keymap.set("n", '<leader>t"', builtin.registers)

telescope.setup({
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
        },
    },
})

telescope.load_extension("ui-select")
telescope.load_extension("fzf")
