local snacks = require("snacks")

snacks.setup({
    bigfile = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    explorer = { enabled = true },
    quickfile = { enabled = true },
    scroll = { enabled = false, animate = { duration = {total = 200}  } },
    statuscolumn = { enabled = true },
    words = { enabled = true },
})

maps = {
    { "<leader>pf", function() Snacks.picker.files() end },
    { "<leader>pe", function() Snacks.picker.explorer() end },
    { "<leader>ps", function() Snacks.picker.grep() end },
    { "<leader>ch", function() Snacks.picker.command_history() end },
    { "grr", function() Snacks.picker.lsp_references() end },
    { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
    { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
    { "<leader>pd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
    -- LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
}

for _, value in ipairs(maps) do
    vim.keymap.set("n", value[1], value[2])
end

vim.api.nvim_create_autocmd("User", {
  pattern = "OilActionsPost",
  callback = function(event)
      if event.data.actions.type == "move" then
          snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
      end
  end,
})
