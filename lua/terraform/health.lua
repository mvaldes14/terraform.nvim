local M = {}

function M.check()
  vim.health.start("Terraform Checks")
  if vim.fn.executable("terraform") ~= 0 then
    vim.health.ok("Terraform found")
    local tf = vim.system({ "terraform", "version" }):wait()
    local tf_version = vim.version.parse(tf.stdout)
    vim.health.ok("Terraform version: " .. tostring(tf_version))
  else
    vim.health.error("Terraform not found in $PATH")
  end
end

return M
