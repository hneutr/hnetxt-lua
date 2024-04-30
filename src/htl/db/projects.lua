local M = SqliteTable("projects", {
    title = {
        type = "text",
        required = true,
        unique = true,
        primary = true,
    },
    created = {
        type = "text",
        default = os.date("%Y%m%d"),
    },
    path = {
        type = "text",
        required = true,
    },
})

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
        return path:is_relative_to(p.path)
    end)

    return #projects > 0 and projects[1] or nil
end

return M
