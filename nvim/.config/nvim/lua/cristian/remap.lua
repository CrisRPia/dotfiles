local map = vim.keymap.set

vim.g.mapleader = " "

map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

map("n", "J", "mzJ`z")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- greatest remap ever
map("x", "<leader>pk", [["_dP]])

-- next greatest remap ever : asbjornHaland
map({ "n", "v" }, "<leader>y", [["+y]])
map("n", "<leader>Y", [["+Y]])

-- Paste from clipboard
map("n", "<leader>P", [["+p]], { desc = "Paste from clipboard" })
map("v", "<leader>P", [["+p]], { desc = "Paste from clipboard" })

map({ "n", "v" }, "<leader>d", [["_d]])

-- This is going to get me cancelled
map("i", "<C-c>", "<Esc>")

map("n", "Q", "<nop>")
map("n", "<C-f>", "<cmd>silent !tmux new tmux-sessionizer<CR>")
map("n", "<leader>fn", function()
    ---@type { filetypes: string[], formatter: string }[]
    local filetype2Formatter = {
        {
            filetypes = { "cs" },
            formatter = "csharpier",
        },
        {
            filetypes = { "python" },
            formatter = "ruff",
        },
        {
            filetypes = { "sql", "mysql", "plsql" },
            formatter = "sleek",
        },
        {
            filetypes = { "javascript", "typescript" },
            formatter = "prettierd",
        },
    }

    local filetype = vim.bo.filetype

    for _, config in ipairs(filetype2Formatter) do
        if vim.tbl_contains(config.filetypes, filetype) then
            vim.cmd("Neoformat " .. config.formatter)
            return
        end
    end

    vim.cmd([[Neoformat]])
end)
map("n", "<leader>fl", vim.lsp.buf.format)

map("n", "<leader>wr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
map("n", "<leader>ih", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
    print("Inlay hint set to " .. tostring(vim.lsp.inlay_hint.is_enabled({})))
end)

-- Window switching
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Wrap
map("n", "<leader>ww", function()
    vim.opt.wrap = not vim.opt.wrap:get()
    if type(vim.opt.wrap) == "table" then
        ---@diagnostic disable-next-line: param-type-mismatch
        print("Wrap set to " .. tostring(vim.opt.wrap:get()))
    end
end)

-- Visual mode indentation remaps
map("v", ">", ">gv", { desc = "Indent right and keep selection" })
map("v", "<", "<gv", { desc = "Indent left and keep selection" })

-- Paste from yank
map("n", "<leader>py", "\"0p")
map("v", "<leader>py", "\"0p")
map("n", "<leader>n", ":cnext<CR>")
map("n", "<leader>N", ":cprev<CR>")

-- for puzzlescript
map("n", "<leader>pzr", function() reset_ts("puzzlescript") end)

function reset_ts(name)
    local out = vim.system({ "tree-sitter", "generate"}):wait()
    print(out.stdout .. out.stderr .. out.code .. out.signal)
    print(require("nvim-treesitter.install").update(name)())
    vim.treesitter.stop()
    vim.treesitter.start()
end
