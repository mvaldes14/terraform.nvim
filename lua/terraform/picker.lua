local config = require("terraform.config")
local utils = require("terraform.utils")

local M = {}

local function find_resource_declaration(address)
  local resource_type, name = address:match("([%w_%-]+)%.([%w_%-]+)$")
  if not resource_type or not name then
    return nil
  end

  for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), "**/*.tf", true, true)) do
    local declaration = string.format('resource "%s" "%s"', resource_type, name)
    for lnum, line in ipairs(vim.fn.readfile(file)) do
      if line:find(declaration, 1, true) then
        return file, lnum
      end
    end
  end
end

local function open_resource_declaration(address)
  local file, lnum = find_resource_declaration(address)
  if not file then
    vim.notify("Terraform resource declaration was not found", vim.log.levels.WARN)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(file))
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end

function M.run()
  local job = utils.run_cmd({ config.opts.program, "state", "list" })
  local resources = vim.tbl_filter(function(resource)
    return resource ~= ""
  end, job.out)
  if #resources == 0 then
    vim.notify("Terraform state contains no resources", vim.log.levels.INFO)
    return
  end

  vim.ui.select(resources, {
    prompt = "Terraform Resources",
  }, function(selection)
    if selection then
      open_resource_declaration(selection)
    end
  end)
end

return M
