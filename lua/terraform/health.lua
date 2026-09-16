local M = {}

local function parse_version(output)
  return vim.version.parse(vim.split(output, "\n", { plain = true })[1])
end

M.check = function()
  if vim.fn.executable("terraform") ~= 0 then
    local tf = vim.system({ "terraform", "version" }):wait()
    if tf.stderr ~= "" then
      vim.health.error("Terraform cannot detect version due to: " .. tf.stderr)
    end

    local tf_version = parse_version(tf.stdout)
    vim.health.ok("Terraform version: " .. tostring(tf_version))
  else
    vim.health.error("Terraform not found in $PATH")
  end

  local has_grep = vim.fn.executable("grep") ~= 0
  local has_ripgrep = vim.fn.executable("rg") ~= 0

  if not has_grep and not has_ripgrep then
    vim.health.error("Need grep or ripgrep as a dependency")
    return
  end

  if has_grep then
    local grep = vim.system({ "grep", "--version" }):wait()
    local grep_version = parse_version(grep.stdout)
    vim.health.ok("grep version: " .. tostring(grep_version))
  end

  if has_ripgrep then
    local ripgrep = vim.system({ "rg", "--version" }):wait()
    local ripgrep_version = parse_version(ripgrep.stdout)
    vim.health.ok("rg version: " .. tostring(ripgrep_version))
  end

end

return M
