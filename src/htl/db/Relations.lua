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
})

function M:get(q)
    return List(M:__get(q))
end

function M:get_annotated(q)
    local rows = M:get(q)

    local urls_by_id = Dict.from_list(
        DB.urls:get(),
        function(u)
            u.label = DB.urls:get_label(u)
            return u.id, Dict(u)
        end
    )
    
    rows:foreach(function(r)
        r.subject_url = urls_by_id[r.subject_url]
        r.subject_label = M.get_label(r.subject_label, r.subject_url)

        if r.object_url then
            r.object_url = urls_by_id[r.object_url]
            r.object_label = M.get_label(r.object_label, r.object_url)
        end
    end)

    return rows
end

function M.get_label(label, url)
    label = label or url and url.label
    
    if label and #label == 0 then
        return
    end
    
    return label
end

function M:insert(r)
    local row = {
        subject_url = r.subject_url,
        subject_label = r.subject_label,
        relation = r.relation,
    }

    if type(r.object) == "number" then
        row.object_url = r.object
    elseif type(r.object) == "string" then
        row.object_label = r.object
    end
    
    M:__insert(row)
end

return M
