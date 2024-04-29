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
    
    if not M:where(row) then
        M:__insert(row)
        M:set_url_label(row)
    end
end

-- function M:test_insert(r, source)
--     local subject = DB.Elements:find(r.subject or source, source)
--     local object = DB.Elements:find(r.object, source)

--     local row = {
--         subject = subject.id,
--         object = object.id,
--         relation = r.relation,
--         type = r.type,
--     }

--     if not M:where(row) then
--         M:__insert(row)
--         M:set_url_label(row)
--     end
-- end

function M:set_url_label(r)
    if r.subject_url and r.relation == "connection" and r.type == "label" then
        DB.urls:set_label(r.subject_url, r.object_label)
    end
end

function M:remove_url(url)
    DB.urls:set_label(url.id)
    DB.Relations:remove({subject_url = url.id})
    DB.Elements:remove({source = url.id})
end

return M
