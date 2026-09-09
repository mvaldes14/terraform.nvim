local config = require("terraform.config")
local ui = require("terraform.ui")
local utils = require("terraform.utils")

local M = {}

local function clean_line(line)
  return line:gsub("\27%[?[0-9;]*m", "")
end

local function append_stream(popup, pending, data)
  if not data or data == "" then
    return
  end

  local lines = vim.split(pending.value .. data, "\n", { plain = true })
  if (pending.value .. data):sub(-1) == "\n" then
    pending.value = ""
  else
    pending.value = table.remove(lines) or ""
  end

  for index, line in ipairs(lines) do
    lines[index] = clean_line(line)
  end
  ui.append_lines(popup, lines)
end

local function flush_stream(popup, pending)
  if pending.value ~= "" then
    ui.append_lines(popup, { clean_line(pending.value) })
    pending.value = ""
  end
end

---@param popup table
---@param args string[]
---@param label string
local function run_in_popup(popup, args, label)
  if popup.running then
    vim.notify("Terraform command is already running", vim.log.levels.WARN)
    return
  end

  popup.running = true
  ui.set_title(popup, "Terraform " .. label .. " (running)")
  ui.set_lines(popup, { "Running terraform " .. label:lower() .. "..." })

  local stdout = { value = "" }
  local stderr = { value = "" }
  local ok, err = pcall(vim.system, args, {
    text = true,
    stdout = function(_, data)
      vim.schedule(function()
        append_stream(popup, stdout, data)
      end)
    end,
    stderr = function(_, data)
      vim.schedule(function()
        append_stream(popup, stderr, data)
      end)
    end,
  }, function(result)
    vim.schedule(function()
      flush_stream(popup, stdout)
      flush_stream(popup, stderr)
      popup.running = false
      ui.set_title(popup, "Terraform " .. label)
      if vim.api.nvim_buf_is_valid(popup.buf) then
        local status = result.code == 0 and "completed" or "failed (exit code " .. result.code .. ")"
        vim.api.nvim_buf_set_lines(
          popup.buf,
          0,
          1,
          false,
          { "Terraform " .. label:lower() .. " " .. status .. "." }
        )
      end
    end)
  end)

  if not ok then
    popup.running = false
    ui.set_title(popup, "Terraform " .. label)
    ui.set_lines(popup, { "Unable to run terraform " .. label:lower() .. ": " .. err })
  end
end

local function terraform_init()
  local output = {}
  local job = utils.run_cmd({ config.opts.program, "init" })
  utils.clean_output(job, output)
  return output
end

local function configure_plan_mappings(popup)
  vim.keymap.set("n", "p", function()
    run_in_popup(popup, { config.opts.program, "plan" }, "Plan")
  end, { buffer = popup.buf, desc = "Run Terraform plan" })

  vim.keymap.set("n", "a", function()
    if popup.running then
      vim.notify("Wait for Terraform to finish before applying", vim.log.levels.WARN)
      return
    end
    vim.ui.input({
      prompt = "Are you sure you want to apply the plan? (yes/no): ",
      default = "no",
    }, function(input)
      if input == "yes" then
        run_in_popup(popup, { config.opts.program, "apply", "-auto-approve" }, "Apply")
      else
        vim.notify("Aborting terraform apply", vim.log.levels.WARN)
      end
    end)
  end, { buffer = popup.buf, desc = "Apply Terraform plan" })
end

local function terraform_validate()
  local job = utils.run_cmd({ config.opts.program, "validate", "-json" })
  local job_string = table.concat(job.out, "\n")
  local parsed_msg = vim.json.decode(job_string, { object = true, array = true })
  if parsed_msg.valid then
    vim.notify("Terraform file is valid")
  else
    local errors = {}
    for _, diagnostic in ipairs(parsed_msg.diagnostics) do
      table.insert(errors, diagnostic.detail .. "\n")
    end
    local error_msg = table.concat(errors, "")
    local msg = "There are " .. parsed_msg.error_count .. " error(s) in your file(s)\n" .. error_msg
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

function M.init()
  if not utils.get_file_extension() then
    return
  end
  utils.change_cwd()
  local init = terraform_init()
  local popup = ui.popup({ title = "Terraform Init" })
  ui.set_lines(popup, init)
end

function M.plan()
  if not utils.get_file_extension() then
    return
  end
  utils.change_cwd()
  local popup = ui.popup({
    title = "Terraform Plan",
    footer = "<q> Close, <p> Plan, <a> Apply",
  })
  configure_plan_mappings(popup)
  run_in_popup(popup, { config.opts.program, "plan" }, "Plan")
end

function M.validate()
  if not utils.get_file_extension() then
    return
  end
  terraform_validate()
end

return M
