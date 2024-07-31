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

function M:where(q)
    if q.path then
        q.path = tostring(q.path)
    end

    return M:__where(q)
end

function M:get(q)
    return List(M:map(function(project)
        project.path = Path(project.path)
        return project
    end, q))
end

function M:insert(row)
    M:__insert(Dict.from_list(
        Dict(M:schema()):keys(),
        function(col) return col, row[col] and tostring(row[col]) end
    ))
    
    DB.urls:get({contains = {path = string.format("%s*", tostring(row.path))}}):foreach(function(url)
        DB.urls:update_project(url.path)
    end)
end

function M:remove(q)
    local projects = M:get({where = Dict(q)})

    projects:sorted(function(a, b)
        return #tostring(a.path) > #tostring(b.path)
    end):foreach(function(project)
        local parent = M.get_by_path(project.path:parent())
        
        if parent then
            if DB.urls:where({project = project.title}) then
                DB.urls:update({
                    where = {project = project.title},
                    set = {project = parent.title},
                })
            end
        end
    end)
    
    M:__remove(q)

    -- called directly to trigger side effects
    DB.urls:remove({project = projects:col('title')})
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

function M.move(move)
    M:get({contains = {path = string.format("%s*", move.source)}}):foreach(function(project)
        local path = move.target / project.path:relative_to(move.source)
        M:update({
            where = {title = project.title},
            set = {path = tostring(path)},
        })
    end)
end

return M
