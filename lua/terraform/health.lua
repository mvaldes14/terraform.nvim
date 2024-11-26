local M = {}


M.check = function()
  vim.health.start("Terraform Checks")
  if vim.fn.executable("terraform") ~= 0 then
    vim.health.ok("Terraform found")
    local executable = vim.system({ "terraform", "version" }):wait()
    local version = vim.version.parse(executable.stdout)
    vim.health.ok("Terraform version: " .. tostring(version))
  else
    vim.health.error("Terraform not found in $PATH")
  end
end

return M
