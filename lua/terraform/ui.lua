local M = {}

---@description Returns a buffer/window to display Terraform command output.
---@param opts? table
---@return table buf, win, running
function M.popup(opts)
  opts = opts or {}
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local win_opts = {
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    relative = "editor",
    style = "minimal",
    title = opts.title or "Terraform",
    title_pos = "center",
    border = "rounded",
    footer = opts.footer or "<q> Close",
    footer_pos = "center",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, win_opts)
  vim.bo[buf].filetype = "terraform-output"
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })
  return { buf = buf, win = win, running = false }
end

---@param popup table
---@param title string
function M.set_title(popup, title)
  if vim.api.nvim_win_is_valid(popup.win) then
    vim.api.nvim_win_set_config(popup.win, { title = title })
  end
end

---@param popup table
---@param lines string[]
function M.set_lines(popup, lines)
  if vim.api.nvim_buf_is_valid(popup.buf) then
    vim.api.nvim_buf_set_lines(popup.buf, 0, -1, false, lines)
  end
end

---@param popup table
---@param lines string[]
function M.append_lines(popup, lines)
  if vim.api.nvim_buf_is_valid(popup.buf) and #lines > 0 then
    vim.api.nvim_buf_set_lines(popup.buf, -1, -1, false, lines)
  end
end

return M
