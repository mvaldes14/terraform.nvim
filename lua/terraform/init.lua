-- Module definition
local M = {}
local telescope_state = require("terraform.telescope_picker")
local terraform_act = require("terraform.actions")

M.plan = function()
    terraform_act.plan()
end

M.state = function()
    telescope_state.run()
end

M.validate = function()
    terraform_act.validate()
end

return M
