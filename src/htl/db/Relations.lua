local M = SqliteTable("Relations", {
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

    local q = {
        subject = subject.id,
        object = object.id,
        relation = r.relation,
        type = r.type,
    }

    local row = M:where(q)
    
    if not row then
        M:set_url_label(q, object)
        return SqliteTable.insert(M, q)
    end
    
    return row.id
end

function M:is_label_relation(r)
    return r.relation == "connection" and r.type == "label"
end

function M:set_url_label(row, object)
    if M:is_label_relation(row) then
        DB.urls:set_label(object.source, object.label)
    end
end

return M
