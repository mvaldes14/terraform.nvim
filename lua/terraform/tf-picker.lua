local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local Job = require("plenary.job")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local function get_state()
  local results = {}
  Job:new({
    command = "terraform",
    args = { "state", "list" },
    cwd = "~/git/terraform/apps/grafana",
    on_exit = function(j, _)
      for _, line in ipairs(j:result()) do
        table.insert(results, line)
      end
    end,
  }):sync()
  return results
end

local run = function()
  vim.cmd("lcd" .. "~/git/terraform/apps/grafana")
  vim.print(vim.fn.getcwd())
  pickers
      .new(_, {
        prompt_title = "Terraform State",
        finder = finders.new_table({
          results = get_state(),
        }),
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_termopen_previewer({
          get_command = function(entry)
            return { "terraform", "state", "show", entry.value }
          end,
          title = "Terraform State",
        }),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            vim.api.nvim_put({ selection.value }, "", false, true)
          end)
          return true
        end,
      })
      :find()
end

return run
