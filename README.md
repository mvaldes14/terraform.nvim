# terraform.nvim

`terraform.nvim` is a Neovim interface for inspecting Terraform state, running plans, and applying changes without leaving the editor.

![Terraform plan output in a floating Neovim window](terraform-plan.png)

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/downloads) or OpenTofu
- Neovim with `vim.system` support (0.10+)

## Installation

The plugin can be lazy-loaded for Terraform files:

```lua
return {
  "mvaldes14/terraform.nvim",
  ft = "terraform",
  opts = {
    program = "terraform", -- or "tofu"
  },
}
```

No Telescope, Plenary, Nui, grep, or ripgrep dependency is required.

Validate the installation with `:checkhealth terraform`.

## Usage

### `:TerraformPlan`

Runs `terraform plan` in a floating window. The window opens immediately with a running indicator and receives stdout and stderr as Terraform produces it. When the command completes, the title and status line are updated.

Within the plan window:

- `p` runs a new plan.
- `a` confirms and runs `terraform apply -auto-approve`; apply output is streamed into the same window.
- `q` closes the window.

### `:TerraformExplore`

Lists state resources with Neovim's native `vim.ui.select` interface. Selecting a resource opens its declaration in the current Terraform project.

![Terraform resource explorer](terraform-explore.png)

### `:TerraformDocs`

Opens the official Terraform Registry documentation for the resource under the cursor. It accepts a resource declaration such as `resource "aws_instance" "web"` or an address such as `aws_instance.web`.

For reliable provider resolution, declare the provider source in `required_providers`:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

If the resource type is invalid or its provider source cannot be found, the command shows a warning instead of opening an unrelated page.

### `:TerraformValidate`

Runs `terraform validate -json` and reports validation failures through Neovim notifications. It is useful from a save autocmd:

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.tf" },
  callback = function()
    vim.cmd("TerraformValidate")
  end,
})
```

### `:TerraformInit`

Runs `terraform init` and displays its output in a floating window.

## Contributing

Suggestions and enhancements are welcome.

## License

See [LICENSE](LICENSE).
