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
        severity = { "ERROR" },
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

vim.keymap.set("n", "<leader>vl", function()
    ---@type virtual_line_enum[]
    local order = {"no", "line", "all"}

    for index, value in ipairs(order) do
        if show_virtual_lines == value then
            local next_index = (index % #order) + 1
            show_virtual_lines = order[next_index]
            break
        end
    end

    reset_diagnostics()
    print("Set virtual lines to " .. show_virtual_lines)
end)
