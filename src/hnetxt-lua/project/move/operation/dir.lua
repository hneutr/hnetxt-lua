local Path = require('hneutil.path')

local Operation = require("hnetxt-lua.project.move.operation")

--------------------------------------------------------------------------------
--                                DirOperation                                --
--------------------------------------------------------------------------------
local DirOperation = table.default({}, Operation)
DirOperation.check_source = Path.is_dir

function DirOperation.map_source_to_target(source, target)
    -- makes a map path of paths in a relative to b
    local map = {}
    for _, subsource in ipairs(Path.iterdir(source)) do
        map[subsource] = Path.joinpath(target, Path.relative_to(subsource, source))
    end
    return map
end

function DirOperation.process(map, mirrors_map)
    map = table.default({}, map or {}, mirrors_map or {})

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

DirOperation.to_files = {}
function DirOperation.to_files.map_source_to_target(source, target)
    local map = DirOperation.map_source_to_target(source, target)
    local source_dir_file = Operation.dir_file_of(source)
    local target_dir_file = map[source_dir_file]

    if target_dir_file then
        map[source_dir_file] = Path.with_stem(target_dir_file, Path.name(source))
    end

    return map
end

return DirOperation
