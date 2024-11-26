# Overview

If you do a lot of terraform manifests, and you would like to see quickly the current state of your objects or how the plan would look like, this plugin is for you.

# Requirements

- [ Terraform ](https://developer.hashicorp.com/terraform/downloads)
- [ Plenary ](https://github.com/nvim-lua/plenary.nvim)
- [ Telescope ](https://github.com/nvim-telescope/telescope.nvim)
- [ Nui ](https://github.com/MunifTanjim/nui.nvim)
- Ripgrep or grep


# Installation
Would recommend you install it with Lazy since it can just load the plugin when a terraform file is detected. 

- Lazy
```
return {
  "mvaldes14/terraform.nvim",
  ft = 'terraform',
  opts = {
    cmd = "grep" -- Options: grep or rg
    program = "terraform" -- Options: terraform or opentofu
  }
}
```

Validate your installation is ready by running :checkhealth terraform
- It will validate that terraform is installed
- Will check if you have either grep or rg

# Usage

It currently supports 3 commands:

- `TerraformPlan` => Will run a plan and show the overall information on a pop-up window

![Plan](terraform-plan.png)

- `TerraformExplore` => Will inspect your terraform state and open up a telescope window with a list of all your resources.
  ![Explorer](terraform-explore.png)

- Selected resource will show a preview of the resource according to the state in the telescope previewer window, useful to get a quick glance for things like VPCs, Security Groups, etc.

- Selecting an item will take you to the resource selected in the right line and file

- `TerraformValidate` => Will run terraform validate in your current file and notify you if there are problems.
**NOTE:** This last command is best used as an event after a save on your buffer, which can be done with:

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.tf" },
  callback = function()
    vim.cmd("TerraformValidate")
  end,
})
```

# Contributing

Open to suggestions and enhancements

# License

See [LICENSE](LICENSE)
