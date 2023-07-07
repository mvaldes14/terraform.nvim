-- Creates command for easy use

vim.api.nvim_create_user_command("TerraPlan", "lua require('terraform').plan()", {})
vim.api.nvim_create_user_command("TerraApply", "lua require('terraform').apply()", {})
vim.api.nvim_create_user_command("Tstate", "lua require('terraform').state()", {})
