vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
    callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set("n", "gd", function()
            vim.lsp.buf.definition()
        end, opts)
        vim.keymap.set("n", "gl", function()
            vim.diagnostic.open_float()
        end, opts)
    end,
})

local severity = vim.diagnostic.severity

---@alias virtual_line_enum "line" | "all" | "no"
---@type virtual_line_enum
local show_virtual_lines = "no"

local vt_severity = { error = true, warn = false, hint = false, info = false }

---@type vim.diagnostic.Opts
local diagnostic_config = {
    virtual_lines = function ()
        if show_virtual_lines == "no" then
            ---@type vim.diagnostic.Opts.VirtualLines
            return { format = function() return nil end }
        elseif show_virtual_lines == "line" then
            ---@type vim.diagnostic.Opts.VirtualLines
            return { current_line = true }
        elseif show_virtual_lines == "all" then
            return { current_line = false }
        end
    end,
    underline = true,
    severity_sort = true,
    update_in_insert = false,
    float = {
        style = "minimal",
        border = "rounded",
        source = true,
    },
    virtual_text = {
        format = function(diag)
            local sev = vim.diagnostic.severity[diag.severity]:lower()
            return vt_severity[sev] and diag.message or nil
        end,
    },
    signs = {
        linehl = {
            [severity.ERROR] = "BufferVisibleERROR",
            [severity.WARN] = "BufferVisibleWARN",
            [severity.HINT] = "BufferVisibleHINT",
            [severity.INFO] = "BufferVisibleINFO",
        },
        numhl = {
            [severity.ERROR] = "DiagnosticSignERROR",
            [severity.WARN] = "DiagnosticSignWARN",
            [severity.HINT] = "DiagnosticSignHINT",
            [severity.INFO] = "DiagnosticSignINFO",
        },
        text = {
            [severity.ERROR] = "",
            [severity.WARN] = "",
            [severity.HINT] = "",
            [severity.INFO] = "",
        },
    },
}
local function reset_diagnostics()
    vim.diagnostic.config(diagnostic_config)
end

reset_diagnostics()


require("cristian.configuration_handler").append({
    {
        name = "LSP",
        type = "Namespace",
        children = {
            {
                name = "inlay hints",
                type = "Toggle",
                get = function() return vim.lsp.inlay_hint.is_enabled({}) end,
                set = function(v) vim.lsp.inlay_hint.enable(v) end,
            },
            {
                name = "virtual lines",
                type = "Enum",
                values = { "no", "line", "all" },
                get = function() return show_virtual_lines end,
                set = function(v)
                    show_virtual_lines = v --[[@as virtual_line_enum]]
                    reset_diagnostics()
                end,
            },
            {
                name = "virtual text",
                type = "Namespace",
                get = function()
                    for _, v in pairs(vt_severity) do
                        if v then return true end
                    end
                    return false
                end,
                set = function(_) end,
                children = {
                    {
                        name = "error",
                        type = "Toggle",
                        get = function() return vt_severity.error end,
                        set = function(v) vt_severity.error = v; reset_diagnostics() end,
                    },
                    {
                        name = "warn",
                        type = "Toggle",
                        get = function() return vt_severity.warn end,
                        set = function(v) vt_severity.warn = v; reset_diagnostics() end,
                    },
                    {
                        name = "hint",
                        type = "Toggle",
                        get = function() return vt_severity.hint end,
                        set = function(v) vt_severity.hint = v; reset_diagnostics() end,
                    },
                    {
                        name = "info",
                        type = "Toggle",
                        get = function() return vt_severity.info end,
                        set = function(v) vt_severity.info = v; reset_diagnostics() end,
                    },
                },
            },
        },
    },
})
