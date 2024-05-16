local M = {}

function M:is_mirror(path)
    return M:get_kind(path) ~= nil
end

function M:get_kind(path)
    local dir = path:parent()

    for kind in Conf.mirror:keys():iter() do
        if Conf.mirror[kind].path == dir then
            return kind
        end
    end

    return
end

function M:_get_path(source, kind)
    if source then
        return Conf.mirror[kind].path / string.format("%s.md", tostring(source.id))
    end
end

function M:get_path(path, kind)
    local source = M:get_source(path)

    return M:_get_path(source, kind)
end

function M:get_paths(path)
    local source = M:get_source(path)

    local paths = Dict()
    Conf.mirror:keys():foreach(function(kind)
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
        return not Conf.mirror[kind].exclude_from_statusline
    end):transform(function(kind)
        return Conf.mirror[kind].statusline_str
    end):sorted():join(" | ")
end

return M
