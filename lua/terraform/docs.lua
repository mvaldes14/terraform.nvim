local M = {}

local function resource_type_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local resource_type = line:match('resource%s+"([%w_%-]+)"')
  if resource_type then
    return resource_type
  end

  local column = vim.api.nvim_win_get_cursor(0)[2] + 1
  for resource in line:gmatch("[%w_%-]+%.[%w_%-]+") do
    local start_column = line:find(resource, 1, true)
    if start_column and column >= start_column and column <= start_column + #resource then
      return resource:match("^([%w_%-]+)")
    end
  end

  return vim.fn.expand("<cword>")
end

local function split_resource_type(resource_type)
  local provider, resource = resource_type:match("^([%w%-]+)_(.+)$")
  if not provider or not resource then
    return nil
  end
  return provider, resource
end

local function provider_source(provider)
  local files = vim.fn.globpath(vim.fn.getcwd(), "**/*.tf", true, true)
  for _, file in ipairs(files) do
    local lines = vim.fn.readfile(file)
    local source = table.concat(lines, "\n"):match(provider .. "%s*=%s*{.-source%s*=%s*\"([^\"]+)\"")
    if source then
      return source
    end
  end
end

function M.open_resource()
  local resource_type = resource_type_at_cursor()
  local provider, resource = split_resource_type(resource_type)
  if not provider then
    vim.notify(
      "TerraformDocs: place the cursor on a resource type or resource address",
      vim.log.levels.WARN
    )
    return
  end

  local source = provider_source(provider)
  if not source then
    vim.notify(
      string.format("TerraformDocs: unable to find required_providers source for %q", provider),
      vim.log.levels.WARN
    )
    return
  end

  local parts = vim.split(source, "/", { plain = true })
  local namespace, name
  if #parts == 2 then
    namespace, name = parts[1], parts[2]
  elseif #parts == 3 and parts[1] == "registry.terraform.io" then
    namespace, name = parts[2], parts[3]
  else
    vim.notify(string.format("TerraformDocs: invalid provider source %q", source), vim.log.levels.WARN)
    return
  end

  local url = string.format(
    "https://registry.terraform.io/providers/%s/%s/latest/docs/resources/%s",
    namespace,
    name,
    resource
  )
  vim.ui.open(url)
end

return M
