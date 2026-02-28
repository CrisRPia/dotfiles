local lspconfig = require("lspconfig")

require("mason").setup({
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
    }
})
local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({})

for _, value in ipairs(mason_lspconfig.get_installed_servers()) do
    vim.lsp.enable(value)
end

vim.lsp.enable({
    -- Enable extra lsps here.
})

lspconfig.nushell.setup({
    cmd = { "nu", "--lsp" },
    filetypes = { "nu" },
    root_dir = lspconfig.util.root_pattern("env.nu", "config.nu", ".git"),
})

lspconfig.sourcekit.setup({})
