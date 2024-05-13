local M = {}

function M:set_conf()
    M.conf = Dict(Conf.mirror)

    local dir = Conf.paths.mirrors_dir
    M.conf:foreach(function(kind, conf)
        conf.path = dir / kind
        conf.statusline_str = conf.statusline_str or kind
    end)
end

function M:is_mirror(path)
    return M:get_kind(path) ~= nil
end

function M:get_kind(path)
    local dir = path:parent()

    for kind in M.conf:keys():iter() do
        if M.conf[kind].path == dir then
            return kind
        end
    end

    return
end

function M:_get_path(source, kind)
    if source then
        return M.conf[kind].path / string.format("%s.md", tostring(source.id))
    end
end

function M:get_path(path, kind)
    local source = M:get_source(path)

    return M:_get_path(source, kind)
end

function M:get_paths(path)
    local source = M:get_source(path)

    local paths = Dict()
    M.conf:keys():foreach(function(kind)
        local p = M:_get_path(source, kind)

        if p and p:exists() then
            paths[kind] = p
        end
    end)

    return paths
end

function M:get_source(path)
    local source = DB.urls:get_file(path)

    if source then
        return source
    elseif M:is_mirror(path) then
        return DB.urls:where({id = tonumber(path:stem())})
    end
end

function M:get_strings(path)
    return M:get_paths(path):keys():filter(function(kind)
        return not M.conf[kind].exclude_from_statusline
    end):transform(function(kind)
        return M.conf[kind].statusline_str
    end):sorted():join(" | ")
end

M:set_conf()

return M
