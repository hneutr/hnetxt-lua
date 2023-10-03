local Dict = require("hl.Dict")
local Path = require('hl.path')

local Operation = require('htl.operator.operation')

local M = Dict.from(Operation)
M.type = "dir"
M.check_source = Path.is_dir

function M.map_source_to_target(source, target)
    -- makes a map path of paths in a relative to b
    local map = {}
    for _, subsource in ipairs(Path.iterdir(source)) do
        map[subsource] = Path.join(target, Path.relative_to(subsource, source))
    end
    return map
end

function M.move(map, mirrors_map)
    map = Dict.from(map or {}, mirrors_map or {})

    local dirs = {}
    for source, target in pairs(map) do
        Path.write(target, Path.read(source))
        Path.unlink(source)
        dirs[#dirs + 1] = Path.parent(source)
    end

    for _, dir in ipairs(dirs) do
        if Path.is_dir(dir) then
            Path.rmdir(dir, true)
        end
    end
end

M.to_files = {}
function M.to_files.map_source_to_target(source, target)
    local map = M.map_source_to_target(source, target)
    local source_dir_file = Operation.dir_file_of(source)
    local target_dir_file = map[source_dir_file]

    if target_dir_file then
        map[source_dir_file] = Path.with_stem(target_dir_file, Path.name(source))
    end

    return map
end

return M
