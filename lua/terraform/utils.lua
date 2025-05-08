local M = {}

---@param cmd table
---@return table: out, err
function M.run_cmd(cmd)
    local results = vim.system(cmd, { text = true }):wait()
    local out = vim.fn.split(results.stdout, "\n")
    local err = vim.fn.split(results.stderr, "\n")
    return { out = out, err = err }
end

function M.get_file_extension()
    -- Gets current file extension
    if vim.fn.expand("%:e") == "tf" then
        return true
    else
        print("Not a terraform file")
        return false
    end
end

function M.change_cwd()
    local cwd = vim.fn.expand("%:p:h")
    vim.fn.execute("lcd " .. cwd)
end

function M.clean_output(job_result, output_result)
    if job_result.err then
        for i in ipairs(job_result.err) do
            local clean = string.gsub(job_result.err[i], "\27%[?[0-9;]*m", "")
            table.insert(output_result, clean)
        end
    end
    for i in ipairs(job_result.out) do
        if i ~= "" then
            local clean = string.gsub(job_result.out[i], "\27%[?[0-9;]*m", "")
            table.insert(output_result, clean)
        end
    end
end

return M
