require("mason").setup({
    registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
    }
})

local mason_lspconfig = require("mason-lspconfig")
mason_lspconfig.setup({})

-- Require lspconfig to populate Neovim's native `vim.lsp.config` with defaults
require("lspconfig")

-- 1. Enable Mason-installed servers (You were already doing this perfectly)
for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
    vim.lsp.enable(server)
end
