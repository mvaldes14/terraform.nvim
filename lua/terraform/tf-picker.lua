local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local Job = require("plenary.job")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}

local get_state = function()
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

local generate_pattern = function(resource, name)
  return string.format('"%s" " %s"', resource, name)
end

local find_lnum_in_file = function(pattern, file)
  print(pattern, file)
  local results = {}
  Job:new({
    command = "grep",
    args = { "-rn", pattern, file },
    on_exit = function(j, _)
      for _, line in ipairs(j:result()) do
        print(vim.inspect(j:result()))
        local path, lnum = line:match("(.*):(%d+)")
        results["lnum"] = lnum
        results["path"] = path
      end
    end,
  }):sync()
  return results
end

local run = function(opts)
  vim.cmd("lcd" .. "~/git/terraform/apps/grafana")
  opts = opts or {}
  pickers
      .new(opts, {
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
            local resource, name = string.match(selection.value, "(.*)%.(.*)")
            local pattern = generate_pattern(resource, name)
            local file_meta = find_lnum_in_file(pattern, vim.fn.getcwd())
            print(vim.inspect(file_meta))
            -- vim.api.nvim_command("e +" .. lnum .. " " .. )
          end)
          return true
        end,
      })
      :find()
end

M.run = function()
  run()
end

return M
