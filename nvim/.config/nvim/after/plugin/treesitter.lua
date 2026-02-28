---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {},
    -- nu grammar is buggy
    ignore_install = { "nu" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    indent = {
        enable = true,
    },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,
        disable = function(lang, buf)
            local max_filesize = 100 * 1024
            local ok, stats =
                pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            return ok and stats ~= nil and stats.size > max_filesize
        end,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },

    incremental_selection = {
        enable = true,
        keymaps = {
            node_incremental = "v",
        },
    },
})

require("nvim-treesitter.install").prefer_git = true

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.puzzlescript = {
  install_info = {
    url = "~/personal/puzzlescript/tree-sitter-puzzlescript",
    files = { "src/parser.c" },
    branch = "main",
    generate_requires_npm = false,
    requires_generate_from_grammar = false,
  },
  filetype = "puzzlescript",
}

vim.filetype.add({
  extension = {
    puzzlescript = "puzzlescript",
  },
})
