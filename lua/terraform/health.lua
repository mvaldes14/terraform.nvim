local M = {}


M.check = function()
  vim.health.start("Terraform Checks")
  if vim.fn.executable("terraform") ~= 0 then
    vim.health.ok("Terraform found")
    local tf = vim.system({ "terraform", "version" }):wait()
    local tf_version = vim.version.parse(tf.stdout)
    vim.health.ok("Terraform version: " .. tostring(tf_version))
  else
    vim.health.error("Terraform not found in $PATH")
  end
  vim.health.start("Terraform Dependency Checks")
  local grep = vim.system({ "grep", "--version" }):wait()
  local ripgrep = vim.system({ "rg", "--version" }):wait()
  local grep_version = vim.version.parse(grep.stdout)
  local ripgrep_version = vim.version.parse(ripgrep.stdout)
  vim.health.ok("Grep version: " .. tostring(grep_version))
  vim.health.ok("Ripgrep version: " .. tostring(ripgrep_version))
  if not grep or not ripgrep then
    vim.health.error("Need grep or ripgrep as a dependency")
  end
end

return M
