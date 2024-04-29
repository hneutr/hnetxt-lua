
local M = require("sqlite.tbl")("Elements", {
    id = true,
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    label = "text",
    source = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    project = {
        type = "text",
        reference = "projects.title",
        on_delete = "cascade",
        required = true,
    },
})

function M:find(element, source)
    local q = {source = source}

    if type(element) == "number" then
        q.url = element
    elseif type(element) == "string" then
        q.label = element
    else
        return {}
    end
    
    M:insert(q)
    return M:where(q).id
end

function M:insert(r)
    local row = {
        source = r.source,
    }
    
    if r.url and not r.label then
        row.url = r.url
    elseif r.label and not r.url then
        row.label = r.label
    else
        return
    end
    
    if not M:where(row) then
        row.project = DB.urls:where({id = r.source}).project
        M:__insert(row)
    end
end

function M:get(q)
    return List(M:__get(q))
end

return M
