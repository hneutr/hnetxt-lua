local Link = require("htl.text.Link")
local URLDefinition = require("htl.text.URLDefinition")

local M = SqliteTable("urls", {
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

    return SqliteTable.insert(M, {
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

    local rows = List(M:map(M.__fmt, q))

    long_vals:foreach(function(col, vals)
        rows = rows:filter(function(r) return vals:contains(r[col]) end)
    end)

    return rows
end

function M.__fmt(u)
    u.path = Path(u.path)

    u.label = M:get_label(u)

    return Dict(u)
end

function M:clean()
    local project_to_path = Dict.from_list(
        DB.projects:get(),
        function(p) return p.title, p.path end
    )

    local ids_to_remove =  M:get():filter(function(u)
        local keep = true
        
        keep = keep and u.path:exists()
        keep = keep and u.path ~= M.unanchored_path
        keep = keep and u.path:is_relative_to(project_to_path[u.project])
        return not keep
    end):col('id')

    if #ids_to_remove > 0 then
        M:remove({id = ids_to_remove})
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
    local present = Set()

    for line in lines:iter() do
        local link = URLDefinition:from_str(line)

        if link then
            local id = tonumber(link.url)
            present:add(id)
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

    local absent = Set(
        M:get({where = {path = path, resource_type = "link"}}):col('id')
    ):difference(present):vals()

    if #absent > 0 then
        M:update({
            where = {id = absent},
            set = {path = tostring(M.unanchored_path)},
        })
    end
end

function M.get_fuzzy_path(url, dir)
    local path = url.path
    
    if url.resource_type == 'link' and url.label and #url.label > 0 then
        path = path:with_name(path:name() .. M.link_delimiter .. url.label)
    end

    if dir then
        path = path:relative_to(dir)
    end

    return tostring(path)
end

function M:get_fuzzy_paths(dir)
    local q
    if dir then
        q = {contains = {path = string.format("%s*", tostring(dir))}}
    end

    return M:get(q):filter(function(url)
        return url.path ~= M.unanchored_path
    end):transform(M.get_fuzzy_path, dir):sorted(function(a, b) return #a < #b end)
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

function M:set_label(id, label)
    M:update({
        where = {id = id},
        set = {label = label or ""},
    })
end

function M:get_label(url)
    local label = url.label

    if not label or #label == 0 then
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
        label = url.label or M:get_label(url),
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
