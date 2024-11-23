local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local run_cmd = require("telescope.utils").get_os_command_output
local utils = require("terraform.utils")
local config = require("terraform.config")

local M = {}

---@param resource any
---@param name any
---@return string
local function generate_pattern(resource, name)
  return string.format('%s" "%s', resource, name)
end

---@param pattern string
---@param file string
local function find_lnum_in_file(pattern, file)
  local cmd = config.opts.cmd
  local quoted_pattern = string.format('"%s"', pattern)
  local job = utils.spawn_job(cmd, { "-rn", quoted_pattern, file })
  local results = {}
  for _, line in ipairs(job) do
    local path, lnum = line:match("(.*):(%d+)")
    results["lnum"] = lnum
    results["path"] = path
  end
  return results
end

function M.run()
  local results, rc, err = run_cmd({ "terraform", "state", "list" })
  -- TODO: Find a better way to notify user they don't have their state setup or initialized
  if rc ~= 0 then
    print(rc, vim.inspect(err))
    return
  end
  pickers
      .new({}, {
        prompt_title = "Terraform Resources",
        finder = finders.new_table({
          results = results
        }),
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_termopen_previewer({
          get_command = function(entry)
            return { "terraform", "state", "show", entry.value }
          end,
        }),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local resource, name = string.match(selection.value, "(.*)%.(.*)")
            local pattern = generate_pattern(resource, name)
            local file_meta = find_lnum_in_file(pattern, vim.fn.getcwd())
            vim.api.nvim_command("e +" .. file_meta["lnum"] .. " " .. file_meta["path"])
          end)
          return true
        end,
      })
      :find()
end

return M
