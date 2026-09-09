local state = require("terraform.picker")
local action = require("terraform.actions")
local config = require("terraform.config")
local docs = require("terraform.docs")

-- Module definition
local M = {}
-- @param opts table
M.setup = function(opts)
    config.opts = vim.tbl_deep_extend("force", config.opts, opts or {})
end

M.plan = function()
    action.plan()
end

M.state = function()
    state.run()
end

M.validate = function()
    action.validate()
end

M.init = function()
    action.init()
end

M.docs = function()
    docs.open_resource()
end

return M
