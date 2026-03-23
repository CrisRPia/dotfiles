local config_handler = require("cristian.configuration_handler")

config_handler.create({
    title = "Settings",
    namespace = "settings",
    backup_path = vim.fn.stdpath("config") .. "/settings_export.json",
})

config_handler.append({
    {
        name = "Status Column",
        type = "Namespace",
        children = {
            {
                name = "folds",
                type = "Toggle",
                get = function() return StatusColumnConfig.folds end,
                set = function(v)
                    StatusColumnConfig.folds = v
                    StatusColumnApply()
                end,
            },
            {
                name = "absolute line numbers",
                type = "Toggle",
                get = function() return StatusColumnConfig.absolute_line_numbers end,
                set = function(v)
                    StatusColumnConfig.absolute_line_numbers = v
                    StatusColumnApply()
                end,
            },
        },
    },
    {
        name = "Editor",
        type = "Namespace",
        children = {
            {
                name = "word wrap",
                type = "Toggle",
                get = function() return vim.go.wrap end,
                set = function(v)
                    vim.go.wrap = v
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(win).relative == "" then
                            vim.wo[win].wrap = v
                        end
                    end
                end,
            },
            {
                name = "whitespace chars",
                type = "Toggle",
                get = function() return vim.go.list end,
                set = function(v)
                    vim.go.list = v
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(win).relative == "" then
                            vim.wo[win].list = v
                        end
                    end
                end,
            },
            {
                name = "cursorline",
                type = "Toggle",
                get = function() return vim.go.cursorline end,
                set = function(v)
                    vim.go.cursorline = v
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(win).relative == "" then
                            vim.wo[win].cursorline = v
                        end
                    end
                end,
            },
            {
                name = "spell",
                type = "Toggle",
                get = function() return vim.go.spell end,
                set = function(v)
                    vim.go.spell = v
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(win).relative == "" then
                            vim.wo[win].spell = v
                        end
                    end
                end,
            },
            (function()
                local cols = {}
                local function col_lt(a, b) return tonumber(a) < tonumber(b) end
                local function apply()
                    local active = {}
                    for col, on in pairs(cols) do
                        if on then table.insert(active, col) end
                    end
                    table.sort(active, col_lt)
                    local val = table.concat(active, ",")
                    vim.go.colorcolumn = val
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(win).relative == "" then
                            vim.wo[win].colorcolumn = val
                        end
                    end
                end
                return {
                    name = "colorcolumn",
                    type = "DynamicNamespace",
                    values = { "80", "100", "120", "150" },
                    schema = {
                        validate = function(input)
                            local n = tonumber(vim.trim(input))
                            return (n and n > 0 and n == math.floor(n)) and tostring(n) or nil
                        end,
                        compare = col_lt,
                        make_toggle = function(value)
                            return {
                                get = function() return cols[value] == true end,
                                set = function(v) cols[value] = v; apply() end,
                            }
                        end,
                    },
                }
            end)(),
        },
    },
})

vim.keymap.set("n", "<leader>set", config_handler.open, { desc = "Settings" })

