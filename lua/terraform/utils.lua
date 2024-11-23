local Job = require("plenary.job")
local M = {}

---@param cmd string
---@param args table
---@return table
function M.spawn_job(cmd, args)
  local results
  Job:new({
    command = cmd,
    args = args,
    on_exit = function(j, _)
      results = j:result()
    end,
  }):sync(99999) -- Needs a big number in case your state is huge
  return results
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
