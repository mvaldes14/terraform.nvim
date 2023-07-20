local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local Job = require("plenary.job")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local run_cmd = require("telescope.utils").get_os_command_output

local M = {}

local generate_pattern = function(resource, name)
	return string.format('%s" "%s', resource, name)
end

local find_lnum_in_file = function(pattern, file)
	local quoted_pattern = string.format('"%s"', pattern)
	local results = {}
	Job:new({
		command = "grep",
		args = { "-rn", quoted_pattern, file },
		on_exit = function(j, _)
			for _, line in ipairs(j:result()) do
				local path, lnum = line:match("(.*):(%d+)")
				results["lnum"] = lnum
				results["path"] = path
			end
		end,
	}):sync()
	return results
end

local run = function(opts)
  local results, rc, err = run_cmd({ "terraform", "state", "list" })
  -- TODO: Find a better way to notify user they don't have their state setup or initialized
  if rc ~= 0 then
    print(rc,vim.inspect(err))
    return
  end
	opts = opts or {}
	pickers
		.new(opts, {
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

M.run = function()
	run()
end

return M
