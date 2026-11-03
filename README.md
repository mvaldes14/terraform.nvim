# terraform.nvim

Plan, inspect, and navigate Terraform infrastructure without leaving Neovim.

terraform.nvim brings common Terraform workflows into your editor: preview changes, browse resources in state, validate configurations, initialize a working directory, and open Terraform Registry documentation.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/downloads) or [OpenTofu](https://opentofu.org/)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) or `grep`

Run `:checkhealth terraform` after installation to check the Terraform executable and search utility.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim), you can load the plugin when opening a Terraform file:

```lua
return {
  "mvaldes14/terraform.nvim",
  ft = "terraform",
  opts = {
    cmd = "grep",          -- "grep" or "rg"
    program = "terraform", -- "terraform" or "opentofu"
  },
}
```

Choose `program = "opentofu"` if you use OpenTofu. Set `cmd = "rg"` to use ripgrep instead of grep.

## Commands

| Command | What it does |
| --- | --- |
| `:TerraformPlan` | Run a plan and display its summary in a popup. |
| `:TerraformFind` | Browse resources from Terraform state and jump to the matching definition in your files. |
| `:TerraformValidate` | Run `terraform validate` and show validation feedback. |
| `:TerraformInit` | Run `terraform init` and display its output in a popup. |
| `:TerraformDocs` | Open Terraform Registry documentation for the resource, data source, or provider block under the cursor. |

### Validate on save (optional)

If you'd like to validate whenever you save a Terraform file, add this autocommand to your Neovim configuration:

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.tf",
  callback = function()
    vim.cmd("TerraformValidate")
  end,
})
```

### Suggested keymaps (optional)

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "terraform",
  callback = function()
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, {
        buffer = 0,
        desc = "[Tf] " .. desc,
        silent = true,
      })
    end

    map("<leader>tp", "<cmd>TerraformPlan<cr>", "Plan")
    map("<leader>ti", "<cmd>TerraformInit<cr>", "Init")
    map("<leader>te", "<cmd>TerraformFind<cr>", "Find")
    map("<leader>td", "<cmd>TerraformDocs<cr>", "Docs")
  end,
})
```

## Troubleshooting

- **A command cannot find Terraform or OpenTofu:** Check that the chosen executable is installed and on your `PATH`, and that `program` matches it.
- **Resource browsing returns no results:** Check that you're working in the intended Terraform directory and that its state contains resources.
- **Setup checks fail:** Run `:checkhealth terraform` and confirm that `grep` or `rg` is available.

## Contributing

Bug reports, suggestions, and pull requests are welcome. Please include reproduction steps when reporting an issue.

## License

See [LICENSE](LICENSE).
