local utils = require("terraform.utils")
local config = require("terraform.config")
local ui = require("terraform.ui")

-- Runs Terraform Init when needed
local function terraform_init()
    local output = {}
    local job = utils.run_cmd({ config.opts.program, "init" })
    utils.clean_output(job, output)
    return output
end

-- Runs terraform plan and places output in popup
---@return table: output of the command
local function terraform_plan()
    local output = {}
    local job = utils.run_cmd({ config.opts.program, "plan" })
    utils.clean_output(job, output)
    return output
end

-- Runs terraform validate and displays output on notification
local function terraform_validate()
    local job = utils.run_cmd({ "terraform", "validate", "-json" })
    local job_string = table.concat(job.out, "\n")
    local parsed_msg = vim.json.decode(job_string, { object = true, array = true })
    if parsed_msg["valid"] then
        vim.notify("Terraform file is valid")
    else
        local errors = {}
        for _, v in ipairs(parsed_msg["diagnostics"]) do
            local e = vim.tbl_get(v, "detail")
            table.insert(errors, e .. "\n")
        end
        local error_count = vim.tbl_get(parsed_msg, "error_count")
        local error_msg = table.concat(errors, "")
        local msg = "There are " .. error_count .. " error(s) in your file(s)" .. "\n" .. error_msg
        vim.notify(msg, vim.log.levels.ERROR)
    end
end

local M = {}

M.init = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    local init = terraform_init()
    local float = ui.popup()
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, init)
end

M.plan = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    local plan = terraform_plan()
    local float = ui.popup()
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, plan)
end

M.validate = function()
    if not utils.get_file_extension() then
        return
    end
    terraform_validate()
end

return M
