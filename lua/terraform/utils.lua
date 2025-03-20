local M = {}

---@param cmd table
---@return table
M.run_cmd = function(cmd)
    local results = vim.system(cmd, { text = true }):wait()
    local data = vim.fn.split(results.stdout, "\n")
    return data
end

---@description checks the file extention of the current file
M.get_file_extension = function()
    if vim.fn.expand("%:e") == "tf" then
        return true
    else
        print("Not a terraform file")
        return false
    end
end

---@description changes the path
M.change_cwd = function()
    local cwd = vim.fn.expand("%:p:h")
    vim.fn.execute("lcd " .. cwd)
end

---@description creates the floating window
M.create_float = function()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        border = "double",
        style = "minimal",
        height = height,
        width = width,
        row = row,
        col = col,
        title = "Terraform Plan",
        title_pos = "center",
        footer = "<q> Close",
        footer_pos = "center",
    })
    vim.api.nvim_buf_set_option(buf, "wrap", true)

    vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end)
    return { buf = buf, win = win }
end

return M
