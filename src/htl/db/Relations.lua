local M = SqliteTable("Relations", {
    id = true,
    subject = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
        required = true,
    },
    object = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
    relation = {
        type = "text",
        required = true,
    },
    key = "text",
    val = "text",
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
            type = "taxonomy_entry",
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
        subject = M.get_url_id(r.subject or source),
        object = M.get_url_id(r.object),
        relation = r.relation,
        key = r.key,
        val = r.val,
        source = source,
    }
    
    M:set_url_label(q)
    return SqliteTable.insert(M, q)
end

function M:set_url_label(r)
    if r.key == "label" then
        DB.urls:update({
            where = {id = r.source},
            set = {label = r.val},
        })
    end
end

return M
