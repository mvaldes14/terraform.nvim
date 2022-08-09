-- Module definition
local M = {}

-- Finds if the terraform binary is installed in your system
local function terraform_binary()
  -- System call to check if binary is installed and in PATH
  local checker = vim.fn.systemlist('which terraform')
  for _, v in pairs(checker) do
    if not string.match(v, "found") then
      print("Terraform is installed")
    end
  end
end

-- Gets current file extension
local function get_file_extension()
  local extension = vim.fn.expand("%:e")
  if extension == "tf" then
    return true
  end
end

-- Creates a buffer to show results of command
local function buffer_handler(action)
  vim.api.nvim_command("vnew")
  vim.api.nvim_create_buf({}, {})
  local split_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(split_buf, action)
  vim.api.nvim_buf_set_lines(split_buf, 0, 0, false, { "Running terraform " .. action })
  vim.cmd("cd " .. vim.fn.expand("%:h"))
  print(vim.cmd("!pwd"))
  vim.fn.jobstart({"ls", "-lrt"}, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(split_buf, -1, -1, false, data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(split_buf, -1, -1, false, data)
      end
    end
  })
end

-- Executes terraform plan
local function terraform_action(action)
  terraform_binary()
  if get_file_extension() then
    buffer_handler(action)
  end
end

M.plan = function()
  terraform_action("plan")
end

M.apply = function()
  terraform_action("apply")
end


return M
