local M = require("sqlite.tbl")("Relations", {
    id = true,
    subject = {
        type = "integer",
        reference = "Elements.id",
        on_delete = "cascade",
        required = true,
    },
    object = {
        type = "integer",
        reference = "Elements.id",
        on_delete = "cascade",
    },
    relation = {
        type = "text",
        required = true,
    },
    type = "type",
})

function M:get(q)
    return List(M:__get(q))
end

function M:insert(r, source)
    if not source then
        return
    end

    local subject = DB.Elements:find(r.subject or source, source)
    local object = DB.Elements:find(r.object, source)

    local row = {
        subject = subject.id,
        object = object.id,
        relation = r.relation,
        type = r.type,
    }

    if not M:where(row) then
        M:__insert(row)
        M:set_url_label(row, object)
    end
end

function M:set_url_label(row, object)
    if row.relation == "connection" and row.type == "label" and object.label then
        DB.urls:set_label(object.source, object.label)
    end
end

function M:remove_url(url)
    DB.urls:set_label(url.id)
    DB.Elements:remove({source = url.id})
end

return M
