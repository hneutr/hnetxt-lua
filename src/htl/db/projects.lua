local Dict = require("hl.Dict")
local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local M = tbl("projects", {
    title = {
        "text",
        required = true,
        unique = true,
        primary = true,
    },
    created = {"text", default = os.date("%Y%m%d")},
    path = {"text", required = true},
})

function M:insert(row)
    row = Dict({}, row)

    if row.path ~= nil then
        row.path = tostring(row.path)
    end

    if row.created then
        row.created = tostring(row.created)
    end

    M:__insert(row)
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
        local test = path:is_relative_to(p.path)
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

function M.tostring(p)
    return string.format("{title=%s, path=%s, created=%s}", p.title, p.path, p.created)
end

return M
