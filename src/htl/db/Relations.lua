local M = require("sqlite.tbl")("Relations", {
    id = true,
    subject_url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    subject_label = "text",
    object_url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    object_label = "text",
    relation = {
        type = "text",
        required = true,
    },
    type = "type",
})

function M:get(q)
    return List(M:__get(q))
end

function M:insert(r)
    local row = {
        subject_url = r.subject_url,
        subject_label = r.subject_label,
        relation = r.relation,
        type = r.type,
    }

    if type(r.object) == "number" then
        row.object_url = r.object
    elseif type(r.object) == "string" then
        row.object_label = r.object
    end
    
    M:__insert(row)
end

return M
