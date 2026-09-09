local M = {}

---@class Config
---@field program string Which program to use
M.opts = {
  program = "terraform", -- Options: terraform or opentofu
}

return M
