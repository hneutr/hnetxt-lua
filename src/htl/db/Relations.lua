-- TODO: see /todo/get-rid-of-Elements-table.md
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
    source = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
})

function M:get(q)
    return List(M:__get(q))
end

function M.get_url_id(element)
    if type(element) == "number" then
        return element
    elseif type(element) == "string" then
        local q = {
            path = Conf.paths.global_taxonomy_file,
            label = element,
            resource_type = "taxonomy_entry",
        }
        
        local row = DB.urls:where(q)
        return row and row.id or DB.urls:insert(q)
    end
end

function M:insert(r, source)
    if not source then
        return
    end

    local q = {
        subject = DB.Elements:insert(r.subject or source),
        object = DB.Elements:insert(r.object),
        relation = r.relation,
        type = r.type,
        source = source,
    }

    M:set_url_label(q)
    return SqliteTable.insert(M, q)
end

function M:is_label_relation(r)
    return r.relation == "connection" and r.type == "label"
end

function M:set_url_label(r)
    if M:is_label_relation(r) and r.object then
        local object = DB.Elements:where({id = r.object}) or {}
        DB.urls:set_label(r.source, object.label)
    end
end

return M
