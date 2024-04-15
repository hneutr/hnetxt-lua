local M = require("sqlite.tbl")("Relations", {
    id = true,
    subject_url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    subject_string = "string",
    object_url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    object_string = "string",
    relation = {
        type = "text",
        required = true,
    },
})

function M:get(q)
    return List(M:__get(q))
end

function M:insert(r)
    local row = {
        subject_url = r.subject_url,
        subject_string = r.subject_string,
        relation = r.relation,
    }

    if type(r.object) == "number" then
        row.object_url = r.object
    elseif type(r.object) == "string" then
        row.object_string = r.object
    end
    
    M:__insert(row)
end

return M
