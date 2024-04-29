local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")

local M = require("sqlite.tbl")("urls", {
    id = true,
    label = "text",
    project = {
        type = "text",
        reference = "projects.title",
        on_delete = "cascade",
    },
    path = {
        type = "text",
        required = true,
    },
    created = {
        type = "date",
        default = [[strftime('%Y%m%d')]],
        required = true
    },
    resource_type = {
        type = "text",
        required = true,
    },
})

M.unanchored_path = Path("__unanchored__")
M.link_delimiter = Conf.link.delimiter

function M:insert(row)
    if not row.resource_type then
        row.resource_type = row.label and "link" or "file"
    end

    if row.resource_type == "file" then
        if not row.path:exists() or M:get_file(row.path) then
            return
        end
    end

    local project = DB.projects.get_by_path(row.path)

    if not project then
        return
    end

    M:__insert({
        path = tostring(row.path),
        project = project.title,
        label = row.label,
        resource_type = row.resource_type,
        created = row.created or os.date("%Y%m%d"),
    })
end

function M:where(q)
    if q.path then
        q.path = tostring(q.path)
    end

    return M:__where(q)
end

function M:get_file(path)
    return M:where({path = path, resource_type = 'file'})
end

function M:move(source, target)
    local project = DB.projects.get_by_path(target)

    if project then
        M:insert({path = source})
        
        M:update({
            where = {path = tostring(source)},
            set = {
                project = project.title,
                path = tostring(target),
            },
        })
    else
        M:remove({path = tostring(source)})
    end
end

function M:get(q)
    q = q or {}

    local long_cols = List({"id"})
    local long_vals = Dict()

    if q.where then
        long_cols:foreach(function(col)
            local vals = q.where[col]
            if vals and type(vals) == 'table' then
                long_vals[col] = List(vals)
                q.where[col] = nil
            end
        end)
    end

    if #Dict(q.where):keys() == 0 then
        q.where = nil
    end

    local rows = List(M:map(function(url)
        url.path = Path(url.path)
        return url
    end, q))

    long_vals:foreach(function(col, vals)
        rows = rows:filter(function(r) return vals:contains(r[col]) end)
    end)

    return rows
end

function M:clean()
    local ids_to_delete =  M:get():filter(function(url)
        return not url.path:exists() or url.path == M.unanchored_path
    end):transform(function(url)
        return url.id
    end)

    if #ids_to_delete > 0 then
        M:remove({id = ids_to_delete})
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                   links                                    --
--                                                                            --
--------------------------------------------------------------------------------
function M:new_link(path)
    local row = {path = path, resource_type = 'link'}
    M:insert(row)
    
    return M:get({where = row}):sort(function(a, b) return a.id > b.id end)[1]
end

function M:update_link_urls(path, lines)
    local observed_ids = List()

    for line in lines:iter() do
        local link = URLDefinition:from_str(line)

        if link then
            local id = tonumber(link.url)
            observed_ids:append(id)
            M:update({
                where = {id = id},
                set = {
                    path = tostring(path),
                    label = link.label,
                    resource_type = "link",
                },
            })
        end
    end

    local unobserved_ids = M:get({where = {path = path, resource_type = "link"}}):transform(function(u)
        return u.id
    end):filter(function(id)
        return not observed_ids:contains(id)
    end)

    if #unobserved_ids > 0 then
        M:update({
            where = {id = unobserved_ids},
            set = {path = tostring(M.unanchored_path)},
        })
    end
end

function M:get_fuzzy_path(url)
    local path = url.path
    
    if url.resource_type == 'link' and url.label ~= nil and #url.label > 0 then
        path = path:with_name(path:name() .. M.link_delimiter .. url.label)
    end

    return path
end

function M:get_fuzzy_paths(dir)
    local project = DB.projects.get_by_path(dir)

    local query
    if project then
        query = {where = {project = project.title}}
    end

    local urls = M:get(query):filter(function(url)
        return url.path ~= M.unanchored_path
    end)
    
    return urls:transform(function(url)
        return tostring(M:get_fuzzy_path(url):relative_to(project.path))
    end):sorted(function(a, b)
        return #a < #b
    end)
end

function M:get_from_fuzzy_path(path, dir)
    local q = {path = path}
    if path:match(M.link_delimiter) then
        q.path, q.label = unpack(path:split(M.link_delimiter, 1))
    end

    if dir then
        q.path = Path(dir):join(q.path)
    end

    return M:where(q)
end

function M:get_label(url)
    local label_relation = DB.Relations:where({
        subject_url = url.id,
        relation = "connection",
        type = "label",
    })
    
    if label_relation then
        return label_relation.object_label
    end
    
    local label = url.label

    if not label then
        local path = url.path

        if path:name() == tostring(Conf.paths.dir_file) then
            path = path:parent()
        end

        label = path:stem():gsub("-", " ")

        if path:is_relative_to(Conf.paths.language_dir) then
            label = label:gsub("_", "-")
        end
    end
    
    return label
end

function M:get_reference(url)
    return Link({
        label = M:get_label(url),
        url = url.id,
    })
end

function M:set_date(path, date)
    local url = M:get_file(path)
    
    if url then
        M:update({
            where = {id = url.id},
            set = {created = date},
        })
    else
        M:insert({path = path, created = date})
    end
end

return M
