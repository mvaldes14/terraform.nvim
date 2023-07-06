-- Module definition
local M = {}
local Job = require("plenary.job")

-- Finds if the terraform binary is installed in your system
local function terraform_binary()
  local check = vim.fn.systemlist("command -v terraform")
  for _, v in ipairs(check) do
    if string.match(v, "terraform") then
      return true
    else
      print("Terraform is not installed")
      return false
    end
  end
end

-- Gets current file extension
local function get_file_extension()
  if vim.fn.expand("%:e") == "tf" then
    return true
  else
    print("Not a terraform file")
    return false
  end
end

-- Runs a plan against cwd
local function terraform_plan()
  local results = {}
  Job:new({
    command = "terraform",
    args = { "plan", "-json" },
    cwd = "~/git/terraform/apps/grafana",
    on_stderr = function(j, _)
      vim.print(j.result())
    end,
    on_exit = function(j, _)
      for _, line in ipairs(j:result()) do
        table.insert(results, line)
      end
    end,
  }):sync(99999)

  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "Output" })
  for _, v in ipairs(results) do
    local x = vim.json.decode(v)
    print(vim.inspect(x))
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { x["@message"] })
  end
end
-- Executes terraform apply
local function terraform_apply()
  if terraform_binary() and get_file_extension() then
    vim.cmd("lcd" .. vim.fn.expand("%:p:h"))
  end
end

M.plan = function()
  terraform_plan()
end

M.apply = function()
  terraform_apply()
end

return M
