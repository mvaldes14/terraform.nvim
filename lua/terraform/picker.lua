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
    local job
    if config.opts.cmd == "grep" then
        job = utils.run_cmd({ cmd, "-rn", pattern, file })
    else
        job = utils.run_cmd({ cmd, "--line-number", pattern, file })
    end
    local results = {}
    for _, line in ipairs(job.out) do
        local path, lnum = line:match("(.*):(%d+)")
        if path and lnum then
            results["lnum"] = lnum
            results["path"] = path
            return results
        end
    end
    return results
end

function M.run()
    local job = utils.run_cmd({ config.opts.program, "state", "list" })
    if #job.out == 0 then
        vim.notify("No Terraform elements found in state", vim.log.levels.WARN)
        return
    end

    vim.ui.select(job.out, { prompt = "Terraform State" }, function(selection)
        if not selection then
            return
        end

        local resource, name = string.match(selection, "(.*)%.(.*)")
        if not resource or not name then
            vim.notify("Unable to parse Terraform state element: " .. selection, vim.log.levels.ERROR)
            return
        end

        local pattern = generate_pattern(resource, name)
        local file_meta = find_lnum_in_file(pattern, vim.fn.getcwd())
        if not file_meta["path"] or not file_meta["lnum"] then
            vim.notify("Unable to find Terraform definition for: " .. selection, vim.log.levels.ERROR)
            return
        end

        vim.api.nvim_command("edit +" .. file_meta["lnum"] .. " " .. vim.fn.fnameescape(file_meta["path"]))
    end)
end

return M
