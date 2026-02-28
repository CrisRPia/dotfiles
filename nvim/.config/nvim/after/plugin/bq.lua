vim.lsp.config("bqls", {
    settings = {
        project_id = "cx-suite",
        location = "us-east-1",
    },
})

vim.lsp.enable("bqls")
