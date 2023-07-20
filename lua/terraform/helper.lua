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

return M
