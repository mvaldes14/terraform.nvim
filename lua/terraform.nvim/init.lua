local api = vim.api
local buf, win
local position = 0

-- Finds if the terraform binary is installed in your system
local function terraform_binary()
  local checker = vim.fn.systemlist('which terraform')
  for _, v in pairs(checker) do
   if string.match(v, "found") then
    print("Binary not found, can continue")
   end
  end
end


local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'whid')

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  vim.api.nvim_win_set_option(win, 'cursorline', true)

  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Terraform Plan'), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'WhidHeader', 0, 0, -1)
end

local function update_view(direction)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  position = position + direction
  if position < 0 then position = 0 end

  local result = vim.api.nvim_call_function('systemlist', {
      'terraform plan'..position
    })

  if #result == 0 then table.insert(result, '') end
  for k,v in pairs(result) do
    result[k] = '  '..result[k]
  end

  api.nvim_buf_set_lines(buf, 1, 2, false, {center('HEAD~'..position)})
  api.nvim_buf_set_lines(buf, 3, -1, false, result)

  api.nvim_buf_add_highlight(buf, -1, 'whidSubHeader', 1, 0, -1)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Gets current file extension
local function get_file_extension()
  local file = vim.fn.expand("%:p")
  local tempTable = {}
  for w in string.gmatch(file, "%a+") do
    table.insert(tempTable, w)
  end
  local fileExtension = tempTable[#tempTable]
  if fileExtension == "lua" then
    open_window()
  end
end
-- Module definition
local M = {}

M.setup = function()
  terraform_binary()
  get_file_extension()
end


M.setup()


return M
