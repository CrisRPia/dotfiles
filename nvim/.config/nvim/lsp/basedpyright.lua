---@type vim.lsp.Config
return {
    settings = {
        analysis = {
            diagnosticMode = "workspace",
            autoSearchPaths = true,
            inlayHints = {
                callArgumentNames = true,
                genericTypes = true
            },
            typeCheckingMode = "recommended",
            autoFormatStrings = true,
        }
    }
}
