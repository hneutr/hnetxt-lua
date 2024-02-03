local Dict = require("hl.Dict")
local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local Config = require("htl.config")

local M = tbl("mirrors", {
    id = true,
    path = {"text", required = true},
    kind = {"text", required = true},
    url = {
        type = "integer",
        reference = "urls.id",
        on_delete = "cascade",
    },
})

--------------------------------------------------------------------------------
--                                  configs                                   --
--------------------------------------------------------------------------------
M.configs = Dict({
    generic = Dict(Config.get("neomirror")),
    projects = Dict(),
    path_to_project = Dict()
})

function M:get_project_config(path)
    local project = M.configs.path_to_project[tostring(path)]
    if not project then
        project = projects.get_by_path(path)
    end

    if not project then
        return Dict()
    end

    if not M.configs.projects[project.title] then
        M:set_project_config(project)
    end

    return M.configs.projects[project.title]
end

function M:set_project_config(project)
    local config = Dict(project)
    config.mirrors = Dict()
    M.configs.generic:foreach(function(key, mirror_config)
        config.mirrors[key] = project.path:join(mirror_config.dir_prefix, key)
    end)

    M.configs.projects[project.title] = config
end

--------------------------------------------------------------------------------
--                                   mirror                                   --
--------------------------------------------------------------------------------
function M:is_mirror(path)
    local config = M:get_project_config(path)

    if config then
        for kind in config.mirrors:keys():iter() do
            if path:is_relative_to(config.mirrors[kind]) then
                return true
            end
        end
    end

    return false
end

function M:get_mirror(path, kind)
    local url = M:get_source(path)

    if not M:where({url = url.id, kind = kind}) then
        M:insert_kind(url, kind)
    end

    return M:where({url = url.id, kind = kind})
end

function M:get_mirror_path(path, kind)
    local mirror = M:get_mirror(path, kind) or {}
    return mirror.path
end

function M:insert_kind(url, kind)
    local config = M:get_project_config(url.path)
    local kind_path = config.mirrors[kind]
    
    M:__insert({
        path = tostring(kind_path:join(url.id .. ".md")),
        kind = kind,
        url = url.id,
    })
end

function M:get_mirrors(path)
    local url = M:get_source(path)

    if url then
        return M:get({where = {url = url.id}})
    end

    return {}
end

--------------------------------------------------------------------------------
--                                   source                                   --
--------------------------------------------------------------------------------
function M:is_source(path)
    return not M:is_mirror(path)
end

function M:get_source(path)
    local q = {}
    if M:is_mirror(path) then
        q.id = tonumber(path:stem())
    else
        q.path = path
    end

    return urls:where(q)
end

--------------------------------------------------------------------------------
--                                    misc                                    --
--------------------------------------------------------------------------------
function M:get(q)
    return List(M:map(function(mirror)
        mirror.path = Path(mirror.path)
        return mirror
    end, q))
end

function M:clean()
    local ids_to_delete = M:get():filter(function(mirror)
        return not mirror.path:exists()
    end):transform(function(mirror)
        return mirror.id
    end)

    if #ids_to_delete > 0 then
        M:remove({id = ids_to_delete})
    end
end

return M
