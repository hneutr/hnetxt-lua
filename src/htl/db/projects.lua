local tbl = require("sqlite.tbl")

local M = tbl("projects", Conf.db.projects)

function M:insert(row)
    M:__insert(Dict.from_list(
        Dict(M:schema()):keys(),
        function(col)
            return col, row[col] and tostring(row[col])
        end
    ))
end

function M:get(q)
    return List(M:map(function(project)
        project.path = Path(project.path)
        return project
    end, q))
end

function M.get_by_path(path)
    path = Path(path)
    
    local projects = M:get():sorted(function(a, b)
        return #tostring(a.path) > #tostring(b.path)
    end):filter(function(p)
        return p ~= nil and path:is_relative_to(p.path)
    end)

    if #projects == 0 then
        return
    end

    return projects[1]
end

function M.get_path(path)
    local project = M.get_by_path(path) or {}
    return project.path
end

function M.get_title(path)
    local project = M.get_by_path(path) or {}
    return project.title
end

return M
