-- Creates command for easy use

vim.api.nvim_create_user_command("TerraformPlan", "lua require('terraform').plan()", {})
vim.api.nvim_create_user_command("TerraformFind", "lua require('terraform').find()", {})
vim.api.nvim_create_user_command("TerraformValidate", "lua require('terraform').validate()", {})
vim.api.nvim_create_user_command("TerraformInit", "lua require('terraform').init()", {})
vim.api.nvim_create_user_command("TerraformDocs", "lua require('terraform').docs()", {})
