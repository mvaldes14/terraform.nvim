local M = {}
local utils = require("terraform.utils")
local config = require("terraform.config")

-- Runs Terraform Init when needed
local function terraform_init()
    vim.notify("Terraform Init needed, attempting to run it...")
    utils.run_cmd({ config.opts.program, "init" })
end

-- Runs terraform plan and places output in popup
local function terraform_plan()
    local float = utils.create_float()
    local job = utils.run_cmd({ config.opts.program, "plan", "-json" })
    for _, v in ipairs(job) do
        local parsed_msg = vim.json.decode(v)
        local init, _ = string.match(parsed_msg["@message"], "init")
        if parsed_msg["@level"] == "error" and init then
            terraform_init()
        end
        if parsed_msg["@level"] == "error" then
            local msg = string.gsub(parsed_msg["diagnostic"]["summary"], "\n", " ")
            vim.api.nvim_buf_set_lines(float.buf, -1, -1, false, { "Error: " .. msg })
        end
        if parsed_msg["@level"] == "info" and not parsed_msg["change"] then
            vim.api.nvim_buf_set_lines(float.buf, -1, -1, false, { parsed_msg["@message"] })
        end
        if parsed_msg["change"] then
            vim.api.nvim_buf_set_lines(float.buf, -1, -1, false, { parsed_msg["@message"] })
            vim.api.nvim_buf_set_lines(float.buf, -1, -1, false, {
                "Resource: "
                    .. parsed_msg["change"]["resource"]["resource_name"]
                    .. ", address: "
                    .. parsed_msg["change"]["resource"]["resource"]
                    .. ", action: "
                    .. parsed_msg["change"]["action"],
            })
            if parsed_msg["change"]["reason"] then
                vim.api.nvim_buf_set_lines(float.buf, -1, -1, false, { "Reason: " .. parsed_msg["change"]["reason"] })
            end
        end
    end
end

-- Runs terraform validate and displays output on notification
local function terraform_validate()
    local job = utils.run_cmd({ "terraform", "validate", "-json" })
    local job_string = table.concat(job, "\n")
    local parsed_msg = vim.json.decode(job_string, { object = true, array = true })
    if parsed_msg["valid"] then
        vim.notify("Terraform file is valid")
    else
        vim.notify("There are " .. parsed_msg["error_count"] .. " error(s) in your file")
    end
end

M.plan = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    -- runs tf plan
    terraform_plan()
end

M.validate = function()
    if not utils.get_file_extension() then
        return
    end
    terraform_validate()
end

return M
