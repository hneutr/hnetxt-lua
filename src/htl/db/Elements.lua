local M = SqliteTable("Elements", {
    id = true,
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    label = "text",
})

function M:insert(element)
    local r = {}
    if type(element) == "number" then
        r.url = element
    elseif type(element) == "string" then
        r.label = element
    else
        return
    end
    
    local row = M:where(r)
    if not row then
        return SqliteTable.insert(M, r)
    end
    
    return row.id
end

function M:get(q)
    return List(M:__get(q))
end

return M
