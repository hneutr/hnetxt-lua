local Path = require("hl.path")
local db = require("htl.db")

local projects = db.get()['projects']
local urls = db.get()['urls']
local mirrors = db.get()['mirrors']
local Mirror = require("htl.mirror")

local mirror_ids = mirrors:get():transform(function(m) return m.id end)
if #mirror_ids > 0 then
    mirrors:remove({id = mirror_ids})
end

local proj = projects:where({title = "chasefeel"})

function get_old_mirror_kind(path)
    local config = mirrors:get_project_config(path)

    if config then
        for kind in config.mirrors:keys():iter() do
            if path:is_relative_to(config.mirrors[kind]) then
                return kind
            end
        end
    end

    return false
end

local to_remove = List()
local migration_map = List()

urls:get({where = {project = "chasefeel"}}):sort(function(a, b)
    return tostring(a.path) < tostring(b.path)
end):foreach(function(url)
    local path = url.path
    local old_mirrors = Mirror(path):get_mirror_paths()

    if #old_mirrors > 0 then
        old_mirrors:foreach(function(old)
            local kind = get_old_mirror_kind(old)

            if kind then
                local new = mirrors:get_mirror_path(path, kind)
                migration_map:append({source = old, target = new})
            else
                to_remove:append(old)
            end
        end)
    end
end)

migration_map:foreach(function(m)
    print(string.format("%s → %s", m.source:relative_to(proj.path), m.target:relative_to(proj.path)))
end)
