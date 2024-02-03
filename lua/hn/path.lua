local Path = require("hl.Path")

function Path.this()
    return Path(vim.fn.expand('%:p'))
end

function Path.open(path, open_command)
    path = Path(path)
    open_command = open_command or "edit"

    if #path:suffix() > 0 then
        path:parent():mkdir()
    else
        path:mkdir()
    end

    if path:is_dir() then
        -- if it's a directory, open a terminal at that directory
        vim.cmd("silent " .. open_command)
        vim.cmd("silent terminal")

        local term_id = vim.b.terminal_job_id

        vim.cmd("silent call chansend(" .. term_id .. ", 'cd " .. tostring(path) .. "\r')")
        vim.cmd("silent call chansend(" .. term_id .. ", 'clear\r')")
    else
        path:touch()
        vim.cmd("silent " .. open_command .. " " .. tostring(path))
    end
end

return Path
