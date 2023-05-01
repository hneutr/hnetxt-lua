local Path = require('hneutil.path')

local Parser = require("hnetxt-lua.parse")
local Location = require("hnetxt-lua.text.location")

local Operation = require('hnetxt-lua.project.move.operation')

--------------------------------------------------------------------------------
--                               FileOperation                                --
--------------------------------------------------------------------------------
local M = table.default({}, Operation)
M.check_source = Path.is_file

function M.process(map, mirrors_map)
    map = table.default({}, map or {}, mirrors_map or {})

    for source, target in pairs(map) do
        Path.write(target, Path.read(source))
        Path.unlink(source)
    end
end

M.to_mark = {}
function M.to_mark.map_mirrors(map)
    -- point mirrors of the source to mirrors of the target (excluding the target's mark)
    local markless_map = {}
    for source, target in pairs(map) do
        markless_map[source] = Location.from_str(target).path
    end

    return Operation.map_mirrors(markless_map)
end

function M.to_mark.process(map, mirrors_map)
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
        local line_sets = {}

        if Path.exists(target) then
            table.insert(line_sets, Path.readlines(target))
        end

        table.insert(line_sets, Path.readlines(source))

        Path.write(target, Parser.merge_line_sets(line_sets))
        Path.unlink(source)
    end
end

return M