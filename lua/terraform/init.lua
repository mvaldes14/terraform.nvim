-- Module definition
local M = {}

-- Finds if the terraform binary is installed in your system
local function terraform_binary()
  local check = vim.fn.systemlist("command -v terraform")
  for _, v in ipairs(check) do
    if string.match(v, '/usr/bin/terraform') then
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


-- Executes terraform plan
local function terraform_plan()
  if terraform_binary() and get_file_extension() then
      vim.cmd("lcd" .. vim.fn.expand("%:p:h"))
      -- Open terminal and send command
      vim.api.nvim_command("ToggleTerm size=80 direction=vertical")
      vim.api.nvim_command("TermExec cmd='terraform plan'")
  end
end

-- Executes terraform apply
local function terraform_apply()
  if terraform_binary() and get_file_extension() then
    vim.cmd("lcd" .. vim.fn.expand("%:p:h"))
    -- Open terminal and send command
    vim.api.nvim_command("ToggleTerm size=80 direction=vertical")
    vim.api.nvim_command("TermExec cmd='terraform apply'")
  end
end

M.plan = function()
  terraform_plan()
end

M.apply = function()
  terraform_apply()
end

return M
