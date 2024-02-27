local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local Job = require("plenary.job")
local file_extension = require("terraform.helper").get_file_extension
local change_cwd = require("terraform.helper").change_cwd

-- Global Scope so it can be reached
local popup = Popup({
    enter = true,
    focusable = true,
    border = {
        style = "rounded",
        text = {
            top = "Terraform Plan",
            top_align = "center",
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
    Job:new({
        command = "terraform",
        args = { "init" },
        on_exit = function(j, _)
            vim.print(j["code"])
            -- Exit Code 1, something is wrong
            if j["code"] == 1 then
                vim.notify("Terraform Init failed, please run it manually")
            end
        end,
    }):sync()
end

-- Runs terraform plan and places output in popup
local function terraform_plan()
    local results = {}
    Job:new({
        command = "terraform",
        args = { "plan", "-json" },
        on_exit = function(j, _)
            for _, line in ipairs(j:result()) do
                table.insert(results, line)
            end
        end,
    }):sync(99999) -- Needs a long time if the directory has tons of files

    for _, v in ipairs(results) do
        local parsed_msg = vim.json.decode(v)
        local init, _ = string.match(parsed_msg["@message"], "init")
        if parsed_msg["@level"] == "error" and init then
            terraform_init()
        end
        vim.api.nvim_buf_set_lines(popup.bufnr, -1, -1, false, { parsed_msg["@message"] })
        if parsed_msg["change"] then
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
    local results = {}
    Job:new({
        command = "terraform",
        args = { "validate", "-json" },
        on_exit = function(j, _)
            for _, line in ipairs(j:result()) do
                table.insert(results, line)
            end
        end,
    }):sync(99999) -- Needs a long time if the directory has tons of files

    local fixed_table = table.concat(results, "\n")
    local parsed_msg = vim.json.decode(fixed_table, {})
    if parsed_msg["valid"] then
        vim.notify("Terraform is valid")
    else
        vim.notify("There are " .. parsed_msg["error_count"] .. " error(s) in your file")
    end
end

local M = {}

M.plan = function()
    if not file_extension() then
        return
    end
    change_cwd()
    -- opens popup
    popup:mount()
    -- runs tf plan
    terraform_plan()
    -- unmount component when cursor leaves buffer
    popup:on(event.BufLeave, function()
        popup:unmount()
    end)
end

M.validate = function()
    if not file_extension() then
        return
    end
    change_cwd()
    terraform_validate()
end

return M
