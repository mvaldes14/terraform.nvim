local M = {}

---@class Config
---@field cmd string The executable to run
---@field program string Which program to use
M.opts = {
  cmd = "rg",           -- Options: grep or rg
  program = "terraform" -- Options: terraform or opentofu
}

return M
