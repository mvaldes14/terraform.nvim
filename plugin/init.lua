-- Creates command for easy use

vim.api.nvim_create_user_command("TerraformPlan", "lua require('terraform').plan()", {})
vim.api.nvim_create_user_command("TerraformExplore", "lua require('terraform').state()", {})
vim.api.nvim_create_user_command("TerraformValidate", "lua require('terraform').validate()", {})
vim.api.nvim_create_user_command("TerraformInit", "lua require('terraform').init()", {})
