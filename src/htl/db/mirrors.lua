local Dict = require("hl.Dict")

local urls = require("htl.db.urls")
local Config = require("htl.Config")

local M = {}

--------------------------------------------------------------------------------
--                                  configs                                   --
--------------------------------------------------------------------------------
M.configs = Dict({
    generic = Dict(Config.get("mirror")),
})

function M:get_absolute_config()
    if not M.configs.absolute then
        M.configs.absolute = Dict()
        M.configs.generic:keys():foreach(function(key)
            M.configs.absolute[key] = Config.paths['mirrors_dir']:join(key)
        end)
    end

    return M.configs.absolute
end

function M:is_mirror(path)
    return M:get_mirror_kind(path) ~= nil
end

function M:get_mirror_kind(path)
    local config = M:get_absolute_config()

    for kind in config:keys():iter() do
        if path:is_relative_to(config[kind]) then
            return kind
        end
    end

    return
end

function M:get_mirror_path(path, kind)
    path = M:get_source(path) or {}
    path = path.path

    local url = urls:where({path = path, resource_type = 'file'})

    if url then
        return M:get_absolute_config()[kind]:join(string.format("%s.md", tostring(url.id)))
    end
end

function M:get_mirror_paths(path)
    local mirrors = Dict()
    M.configs.generic:keys():foreach(function(kind)
        local mirror = M:get_mirror_path(path, kind)

        if mirror and mirror:exists() then
            mirrors[kind] = mirror
        end
    end)

    return mirrors
end

function M:is_source(path)
    return urls:where({path = path, resource_type = "file"}) and true or false
end

function M:get_source(path)
    if M:is_source(path) then
        return urls:where({path = path, resource_type = "file"})
    elseif M:is_mirror(path) then
        return urls:where({id = tonumber(path:stem())})
    end
end

function M.get_kind_string(kind)
    return M.configs.generic[kind].statusline_name or kind
end

function M:get_mirrors_string(path)
    if M:is_source(path) then
        return M:get_mirror_paths(path):keys():filter(function(kind)
            return not M.configs.generic[kind].exclude_from_statusline
        end):transform(M.get_kind_string):sorted():join(" | ")
    end

    return ""
end

return M
