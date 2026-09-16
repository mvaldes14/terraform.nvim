local M = {}

---@description: Returns a buffer/window to display data on
---@return table: buf, win
M.popup = function(opts)
    opts = opts or {}
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local win_opts = {
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        relative = "editor",
        style = "minimal",
        title = opts.title or "Terraform",
        title_pos = "center",
        border = "rounded",
        footer = opts.footer or "<q> Close",
        footer_pos = "center",
    }
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    local win = vim.api.nvim_open_win(buf, true, win_opts)
    local close = function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    vim.keymap.set({ "n" }, "q", close, { buffer = buf })
    vim.keymap.set({ "n" }, "<Esc>", close, { buffer = buf })
    return { buf = buf, win = win }
end

return M
