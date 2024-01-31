local Dict = require("hl.Dict")
local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local Config = require("htl.config")

local M = tbl("mirrors", {
    id = true,
    source = {"text", required = true},
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
function M:get_mirror_kind(path)
    local config = M:get_project_config(path)

    if config then
        for kind in config.mirrors:keys():iter() do
            if path:is_relative_to(config.mirrors[kind]) then
                return kind
            end
        end
    end

    return
end

function M:is_mirror(path)
    return M:get_mirror_kind(path) ~= nil
end

function M:get(q)
    return List(M:map(function(mirror)
        mirror.path = Path(mirror.path)
        return mirror
    end, q))
end

function M:get_mirror_path(path, kind)
    local source = M:get_source_path(path)

    if not M:where({source = source, kind = kind}) then
        M:insert_kind(source, kind)
    end

    local mirror = M:where({source = source, kind = kind})

    if mirror then
        return mirror.path
    end

    return 
end

function M:get_mirror_paths(source)
    return M:get({where = {source = tostring(source)}}):transform(function(mirror)
        return mirror.path
    end)
end

function M:insert_kind(source, kind)
    local config = M:get_project_config(source)
    local kind_path = config.mirrors[kind]

    if not urls:where({path = source}) then
        urls:insert({path = source})
    end
    
    print(require("inspect")("MUST FILTER TO _FILE_ URLS; add conception of `kind`=file/link to urls"))
    print("also show mirrors that exist for a file on the right hand side of the statusline using the keymap char")
    local id = urls:get({path = source}):transform(function(url)
        return url.id
    end):sort()[1]

    M:__insert({
        source = tostring(source),
        path = tostring(kind_path:join(id .. ".md")),
        kind = kind,
        url = id,
    })
end

--------------------------------------------------------------------------------
--                                   source                                   --
--------------------------------------------------------------------------------
function M:is_source(path)
    return not M:is_mirror(path)
end

function M:get_source_path(path)
    if M:is_mirror(path) then
        return urls:where({id = tonumber(path:stem())}).path
    end

    return path
end

return M
