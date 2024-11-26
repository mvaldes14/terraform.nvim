local M = {}

---@param cmd table
---@return table
function M.run_cmd(cmd)
  local results = vim.system(cmd, { text = true }):wait()
  if results.code ~= 0 then
    error("Error running cmd: " .. results.stderr)
  end
  local data = vim.fn.split(results.stdout, "\n")
  return data
end

function M.get_file_extension()
  -- Gets current file extension
  if vim.fn.expand("%:e") == "tf" then
    return true
  else
    print("Not a terraform file")
    return false
  end
end

function M.change_cwd()
  local cwd = vim.fn.expand("%:p:h")
  vim.fn.execute("lcd " .. cwd)
end

return M
