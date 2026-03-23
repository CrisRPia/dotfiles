vim.api.nvim_set_hl(0, "StatusColAbsolute", { bold = true, fg = "#403d52" })

vim.o.signcolumn = "yes"
vim.opt.relativenumber = true

vim.o.foldcolumn = "1"
vim.o.statuscolumn = "%!v:lua.StatusColumnNumbers()"

StatusColumnConfig = {
    folds = true,
    absolute_line_numbers = true,
}

function _G.StatusColumnNumbers()
    local absolute_number = vim.v.lnum
    local relative_number = vim.v.relnum

    local str = ""

    if StatusColumnConfig.folds then
        str = str .. "%C"
    end

    str = str .. "%s"

    if StatusColumnConfig.absolute_line_numbers then
        str = str .. string.format(" %%#StatusColAbsolute#%3d%%* ", absolute_number)
    else
        str = str .. " "
    end

    if relative_number == 0 then
        local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
        local line_text = vim.api.nvim_buf_get_lines(buf, absolute_number - 1, absolute_number, false)[1] or ""
        local row_width = vim.fn.strdisplaywidth(line_text)

        str = str .. string.format("%%#StatusColRelative#%3s%%* ", tostring(row_width))
    else
        str = str .. string.format("%%#StatusColRelative#%3d%%* ", relative_number)
    end

    str = str .. "%#LineNr#│ %*"

    return str
end

function _G.StatusColumnApply()
    local expr = "%!v:lua.StatusColumnNumbers()"
    local foldcol = StatusColumnConfig.folds and "1" or "0"
    local normal_wins = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative == "" then
            table.insert(normal_wins, win)
        end
    end
    for _, win in ipairs(normal_wins) do
        vim.wo[win].foldcolumn = foldcol
        vim.wo[win].statuscolumn = ""
    end
    for _, win in ipairs(normal_wins) do
        vim.wo[win].statuscolumn = expr
    end
    vim.cmd("redraw!")
end
