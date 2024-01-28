local Path = require('hn.path')

function get_path()
    local path = Path.current_file()
    if Path.is_relative_to(path, vim.b.hnetxt_project_root) then
        return Path.relative_to(path, vim.b.hnetxt_project_root)
    else
        return path
    end
end

function get_statusline()
    return table.concat({
        get_path()
    })
end

return get_statusline
