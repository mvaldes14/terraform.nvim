local utils = require("terraform.utils")
local config = require("terraform.config")
local ui = require("terraform.ui")
local M = {}

local function append_lines(buf, data)
    if not data or data == "" then
        return
    end

    data = utils.strip_ansi(data)
    local lines = vim.split(data, "\n", { plain = true })
    if lines[#lines] == "" then
        table.remove(lines, #lines)
    end
    if #lines == 0 then
        return
    end

    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then
            return
        end
        local line_count = vim.api.nvim_buf_line_count(buf)
        local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        if line_count == 1 and first_line == "" then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        else
            vim.api.nvim_buf_set_lines(buf, line_count, -1, false, lines)
        end
    end)
end

local function clear_lines(buf)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    end
end

local function run_terraform(buf, args, label)
    local display_args = {}
    for _, arg in ipairs(args) do
        if arg ~= "-no-color" then
            table.insert(display_args, arg)
        end
    end
    local command = config.opts.program .. " " .. table.concat(display_args, " ")

    append_lines(buf, "Running: " .. command)
    vim.system(vim.list_extend({ config.opts.program }, args), {
        text = true,
        stdout = function(_, data)
            append_lines(buf, data)
        end,
        stderr = function(_, data)
            append_lines(buf, data)
        end,
    }, function(result)
        append_lines(buf, "")
        if result.code == 0 then
            append_lines(buf, "Done: " .. config.opts.program .. " " .. label)
        else
            append_lines(buf, "Failed: " .. config.opts.program .. " " .. label .. " exited with code " .. result.code)
        end
    end)
end

-- Runs Terraform Init
local function terraform_init(buf)
    run_terraform(buf, { "init", "-no-color" }, "init")
end

-- Runs Terraform Apply
local function terraform_apply(buf)
    run_terraform(buf, { "apply", "-auto-approve", "-no-color" }, "apply")
end

-- Runs terraform plan and places output in popup
local function terraform_plan(buf)
    run_terraform(buf, { "plan", "-no-color" }, "plan")
end

local function format_validate_diagnostics(diagnostics)
    local lines = {}
    for _, diagnostic in ipairs(diagnostics or {}) do
        local severity = diagnostic.severity or "diagnostic"
        local summary = diagnostic.summary or "Terraform diagnostic"
        local location = ""
        local range = diagnostic.range
        if range and range.filename and range.start and range.start.line then
            location = " (" .. range.filename .. ":" .. range.start.line .. ")"
        end

        table.insert(lines, severity:gsub("^%l", string.upper) .. ": " .. summary .. location)
        if diagnostic.detail and diagnostic.detail ~= "" then
            table.insert(lines, diagnostic.detail)
        end
    end
    return table.concat(lines, "\n\n")
end

-- Runs terraform validate and displays output on notification
local function terraform_validate()
    local job = utils.run_cmd({ config.opts.program, "validate", "-json", "-no-color" })
    local job_string = vim.trim(table.concat(job.out, "\n"))
    if job_string == "" then
        local err = vim.trim(table.concat(job.err or {}, "\n"))
        vim.notify(err ~= "" and err or "Terraform validate: no JSON output", vim.log.levels.ERROR)
        return
    end

    local ok, parsed_msg = pcall(vim.json.decode, job_string, { object = true, array = true })
    if not ok then
        local err = vim.trim(table.concat(job.err or {}, "\n"))
        local msg = err ~= "" and err or job_string
        vim.notify("Terraform validate: unable to parse output\n" .. msg, vim.log.levels.ERROR)
        return
    end

    local error_count = parsed_msg.error_count or 0
    local warning_count = parsed_msg.warning_count or 0
    local diagnostics = format_validate_diagnostics(parsed_msg.diagnostics)

    if parsed_msg.valid then
        if warning_count > 0 then
            vim.notify("Terraform validate: valid with " .. warning_count .. " warning(s)\n" .. diagnostics, vim.log.levels.WARN)
        else
            vim.notify("Terraform validate: valid")
        end
    else
        local msg = "Terraform validate: failed with " .. error_count .. " error(s)"
        if warning_count > 0 then
            msg = msg .. " and " .. warning_count .. " warning(s)"
        end
        if diagnostics ~= "" then
            msg = msg .. "\n" .. diagnostics
        end
        vim.notify(msg, vim.log.levels.ERROR)
    end
end

local function get_provider_sources()
    local sources = {}
    for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), "*.tf", false, true)) do
        local current_provider
        for _, line in ipairs(vim.fn.readfile(file)) do
            local provider, source = line:match('^%s*([%w_-]+)%s*=%s*{.-source%s*=%s*"([^"]+)"')
            if provider and source then
                sources[provider] = source
            end

            current_provider = line:match('^%s*([%w_-]+)%s*=%s*{%s*$') or current_provider
            source = line:match('^%s*source%s*=%s*"([^"]+)"')
            if current_provider and source then
                sources[current_provider] = source
            end
            if line:match('^%s*}%s*$') then
                current_provider = nil
            end
        end
    end
    return sources
end

local function get_docs_target()
    for lnum = vim.fn.line("."), 1, -1 do
        local line = vim.fn.getline(lnum)
        local block_type, terraform_type = line:match('^%s*(resource)%s*"([^"]+)"')
        if not block_type then
            block_type, terraform_type = line:match('^%s*(data)%s*"([^"]+)"')
        end
        if block_type and terraform_type then
            return { block_type = block_type, terraform_type = terraform_type }
        end

        local provider = line:match('^%s*provider%s*"([^"]+)"')
        if provider then
            return { block_type = "provider", provider = provider }
        end
    end
end

local function open_url(url)
    if vim.ui.open then
        vim.ui.open(url)
    elseif vim.fn.has("mac") == 1 then
        vim.fn.jobstart({ "open", url }, { detach = true })
    elseif vim.fn.has("unix") == 1 then
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    else
        vim.fn.setreg("+", url)
        vim.notify("Copied Terraform docs URL to clipboard: " .. url)
    end
end

local function terraform_docs()
    local target = get_docs_target()
    if not target then
        vim.notify("No Terraform resource, data source, or provider block found under cursor", vim.log.levels.WARN)
        return
    end

    local provider = target.provider or target.terraform_type:match("^([^_]+)_")
    if not provider then
        vim.notify("Unable to determine provider for " .. target.terraform_type, vim.log.levels.ERROR)
        return
    end

    local source = get_provider_sources()[provider] or ("hashicorp/" .. provider)
    source = source:gsub("^registry%.terraform%.io/", "")
    local url = "https://registry.terraform.io/providers/" .. source .. "/latest/docs"
    if target.block_type == "resource" then
        url = url .. "/resources/" .. target.terraform_type:gsub("^" .. provider .. "_", "")
    elseif target.block_type == "data" then
        url = url .. "/data-sources/" .. target.terraform_type:gsub("^" .. provider .. "_", "")
    end

    open_url(url)
    vim.notify("Opened Terraform docs: " .. url)
end

M.init = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    local float = ui.popup({ title = "Terraform Init" })
    terraform_init(float.buf)
end

M.plan = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    local float = ui.popup({ title = "Terraform Plan", footer = "q close • p plan • a apply" })
    terraform_plan(float.buf)
    vim.keymap.set({ "n" }, "p", function()
        if vim.api.nvim_buf_is_valid(float.buf) then
            clear_lines(float.buf)
            terraform_plan(float.buf)
        end
    end, { buffer = float.buf })
    vim.keymap.set({ "n" }, "a", function()
        if vim.api.nvim_buf_is_valid(float.buf) then
            vim.ui.input({
                prompt = "Are you sure you want to apply the plan? (yes/no): ",
                default = "no",
            }, function(input)
                if input == "yes" then
                    clear_lines(float.buf)
                    terraform_apply(float.buf)
                else
                    vim.notify("Aborting terraform apply", vim.log.levels.WARN)
                    vim.api.nvim_win_close(float.win, true)
                    return
                end
            end)
        end
    end, { buffer = float.buf })
end

M.validate = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    terraform_validate()
end

M.docs = function()
    if not utils.get_file_extension() then
        return
    end
    utils.change_cwd()
    terraform_docs()
end

return M
