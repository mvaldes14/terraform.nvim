local M = {}

---@description: Returns a buffer/window to display data on
---@return table: buf, win
M.popup = function()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local win_opts = {
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        relative = "editor",
        style = "minimal",
        title = "Terraform Plan",
        title_pos = "center",
        border = "rounded",
        footer = "<q> Close, <p> Plan, <a> Apply",
        footer_pos = "center",
    }
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    vim.keymap.set({ "n" }, "q", function()
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_win_close(win, true)
        end
    end, { buffer = buf })
    return { buf = buf, win = win }
end

return M
