local Popup = require("nui.popup")
local utils = require("terraform.utils")

-- Global Scope so it can be reached
local popup = Popup({
  enter = true,
  focusable = true,
  border = {
    style = "rounded",
    text = {
      top = "Terraform Plan",
      top_align = "center",
      bottom = "<q> Close, <r> Plan",
      bottom_align = "center"
    },
  },
  position = "50%",
  size = {
    width = "80%",
    height = "80%",
  },
})

-- Runs Terraform Init when needed
local function terraform_init()
  vim.notify("Terraform Init needed, attempting to run it...")
  local job = utils.spawn_job("terraform", { "init" })
  print(vim.inspect(job))
end

-- Runs terraform plan and places output in popup
local function terraform_plan()
  local job = utils.spawn_job("terraform", { "plan", "-json" })

  for _, v in ipairs(job) do
    local parsed_msg = vim.json.decode(v)
    local init, _ = string.match(parsed_msg["@message"], "init")
    if parsed_msg["@level"] == "error" and init then
      terraform_init()
    end
    if parsed_msg["@level"] == "error" then
      local msg = string.gsub(parsed_msg["diagnostic"]["summary"], "\n", " ")
      vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false,
        { "Error: " .. msg })
    end
    if parsed_msg["@level"] == "info" and not parsed_msg["change"] then
      vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false,
        { parsed_msg["@message"] })
    end
    if parsed_msg["change"] then
      vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false, { parsed_msg["@message"] })
      vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false, {
        "Resource: "
        .. parsed_msg["change"]["resource"]["resource_name"]
        .. ", address: "
        .. parsed_msg["change"]["resource"]["resource"]
        .. ", action: "
        .. parsed_msg["change"]["action"],
      })
      if parsed_msg["change"]["reason"] then
        vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false, { "Reason: " .. parsed_msg["change"]["reason"] })
      end
    end
  end
end

-- Runs terraform validate and displays output on notification
local function terraform_validate()
  local job = utils.spawn_job("terraform", { "validate", "-json" })
  print(vim.inspect(job))

  local fixed_table = table.concat(job, "\n")
  local parsed_msg = vim.json.decode(fixed_table, {})
  if parsed_msg["valid"] then
    vim.notify("Terraform is valid")
  else
    vim.notify("There are " .. parsed_msg["error_count"] .. " error(s) in your file")
  end
end

local M = {}

M.plan = function()
  if not utils.get_file_extension() then
    return
  end
  utils.change_cwd()
  -- opens popup
  popup:mount()
  -- runs tf plan
  terraform_plan()
  -- quit popup on Q
  popup:map("n", "q", function()
    popup:unmount()
  end, { noremap = true })
  popup:map("n", "r", function()
    terraform_plan()
  end, { noremap = true })
  vim.api.nvim_buf_set_option(popup.bufnr, "wrap", true)
  vim.api.nvim_buf_set_option(popup.bufnr, "ro", true)
end


M.validate = function()
  if not utils.get_file_extension() then
    return
  end
  utils.change_cwd()
  terraform_validate()
end

return M
