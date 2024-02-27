local M = {}

M.get_file_extension = function()
    -- Gets current file extension
    if vim.fn.expand("%:e") == "tf" then
        return true
    else
        print("Not a terraform file")
        return false
    end
end

M.change_cwd = function()
    local cwd = vim.fn.expand("%:p:h")
    vim.fn.execute("lcd " .. cwd)
end

return M
