local Mirrors = require("htl.Mirrors")
local Link = require("htl.text.Link")
local Metadata = require("htl.Metadata")

local M = SqliteTable("urls", {
    id = true,
    label = "text",
    project = {
        type = "text",
        reference = "projects.title",
        on_delete = "cascade",
        required = true,
    },
    path = {
        type = "text",
        required = true,
    },
    type = {
        type = "text",
        required = true,
    },
    created = {
        type = "date",
        default = [[strftime('%Y%m%d')]],
        required = true
    },
    modified = {
        type = "date",
        default = [[strftime('%Y%m%d')]],
        required = false
    },
})

function M.should_track(path)
    return path:suffix() == ".md" and not Mirrors:is_mirror(path) and DB.projects.get_by_path(path) ~= nil
end

function M:insert(row)
    row.type = row.type or "file"

    if row.type == "file" and M:get_file(row.path) then
        return
    end

    local project = DB.projects.get_by_path(row.path)
    
    if not project then
        return
    end

    return SqliteTable.insert(M, {
        path = tostring(row.path),
        project = project.title,
        label = row.label or M:path_to_label(row.path),
        type = row.type,
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
    return M:where({path = path, type = 'file'})
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
        keep = keep and u.path:is_relative_to(project_to_path[u.project])
        return not keep
    end):col('id')

    if #ids_to_remove > 0 then
        M:remove({id = ids_to_remove})
    end
end

function M:remove(q)
    M:get({where = Dict(q)}):foreach(M.remove_references_to_url)
    M:__remove(q)
end

function M.remove_references_to_url(url_to_remove)
    local link = M:get_reference(url_to_remove)
    local link_string = tostring(link):escape()

    local url_ids = DB.Relations:get({where = {object = url_to_remove.id}}):col('source')

    if #url_ids > 0 then
        DB.urls:get({where = {id = url_ids}}):foreach(function(url)
            List({url.path, Mirrors:get_path(url.path, "metadata")}):foreach(function(p)
                if p:exists() then
                    p:write(p:read():gsub(link_string, link.label))
                end
            end)
            Metadata.record(url)
        end)
    end
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                    etc                                     --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
function M.move(move)
    local source, target = move.source, move.target
    
    local source_url = M:where({path = source})
    local target_should_exist = M.should_track(target)
    
    if source_url then
        if target_should_exist then
            local to_set = {path = tostring(target)}

            if M.has_default_label(source_url) then
                to_set.label = M:path_to_label(target)
            end

            M:update({
                where = {path = tostring(source)},
                set = to_set,
            })

            M:update_project(target)
        else
            M:remove({path = source})
        end
    elseif target_should_exist then
        M:insert({path = target})
    end
end

function M:update_project(path)
    local project = DB.projects.get_by_path(path)

    if project then
        M:update({
            where = {path = tostring(path)},
            set = {project = project.title},
        })
    else
        M:remove({path = tostring(path)})
    end
end

function M:path_to_label(path)
    if path:name() == tostring(Conf.paths.dir_file) then
        path = path:parent()
    end

    local label = path:stem()
    label = label:gsub("-", " ")
    label = label:gsub("_", "-")
    return label
end

function M.has_default_label(url)
    return url.label == M:path_to_label(url.path)
end

function M:get_reference(url)
    return Link({label = url.label, url = url.id})
end

--------------------------------------------------------------------------------
--                                                                            --
--                                   fuzzy                                    --
--                                                                            --
--------------------------------------------------------------------------------
M.fuzzy = {}

function M.fuzzy.get_path(url, dir)
    local path = url.path

    if dir then
        path = path:relative_to(dir)
    end

    return tostring(path)
end

function M.fuzzy.get_paths(dir)
    local q = {where = {type = "file"}}

    if dir then
        q.contains = {path = string.format("%s*", tostring(dir))}
    end

    return M:get(q):transform(M.fuzzy.get_path, dir):sorted(function(a, b)
        return #a < #b
    end)
end

function M.fuzzy.from_path(path, dir)
    local q = {path = path}

    if dir then
        q.path = Path(dir) / q.path
    end

    return M:where(q)
end

return M
