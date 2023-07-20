-- Module definition
local M = {}
local telescope_state = require("terraform.telescope_picker")
local terraform_plan = require("terraform.actions")


M.plan = function()
  terraform_plan.plan()
end


M.state = function()
  telescope_state.run()
end

return M
