local Path = require('hneutil.path')

local Parser = require("hnetxt-lua.parse")
local Location = require("hnetxt-lua.text.location")

local Operation = require('hnetxt-lua.project.move.operation')

--------------------------------------------------------------------------------
--                               FileOperation                                --
--------------------------------------------------------------------------------
local FileOperation = Operation:extend()
FileOperation.check_source = Path.is_file

function FileOperation.process(map, mirrors_map)
    map = table.default({}, map or {}, mirrors_map or {})

    for source, target in pairs(map) do
        Path.write(target, Path.read(source))
        Path.unlink(source)
    end
end

FileOperation.to_mark = {}
function FileOperation.to_mark.map_mirrors(map)
    -- point mirrors of the source to mirrors of the target (excluding the target's mark)
    local markless_map = {}
    for source, target in pairs(map) do
        markless_map[source] = Location.from_str(target).path
    end

    return Operation.map_mirrors(markless_map)
end

function FileOperation.to_mark.process(map, mirrors_map)
    local parser = Parser()
    for source, target in pairs(map) do
        parser:add_mark_content({
            new_content = Path.readlines(source),
            from_mark_location = Location.from_str(source),
            to_mark_location = Location.from_str(target),
            include_mark = true,
        })

        Path.unlink(source)
    end

    for source, target in pairs(mirrors_map) do
        local line_sets = {Path.readlines(source)}

        if Path.exists(target) then
            line_sets[#line_sets + 1] = Path.readlines(target)
        end

        Path.write(target, Parser.merge_line_sets(line_sets))
        Path.unlink(source)
    end
end

return FileOperation
