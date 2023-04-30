local Path = require("hneutil.path")

local Location = require("hnetxt-lua.text.location")
local Parser = require("hnetxt-lua.parse")

local Operation = require("hnetxt-lua.project.move.operation")

--------------------------------------------------------------------------------
--                               MarkOperation                                --
--------------------------------------------------------------------------------
local MarkOperation = Operation:extend()

MarkOperation.check_source = Operation.is_mark

function MarkOperation.map_mirrors() return {} end

-- this moves source:mark to target (or target:mark, if there is one)
function MarkOperation.process(map)
    if include_mark == nil then
        include_mark = true
    end

    local parser = Parser()

    for source, target in pairs(map) do
        local source_location = Location.from_str(source)
        local target_location = Location.from_str(target)

        parser:add_mark_content({
            new_content = parser:remove_mark_content(source_location),
            from_mark_location = source_location,
            to_mark_location = target_location,
            include_mark = include_mark,
        })
    end
end

MarkOperation.to_dir_file = {}
function MarkOperation.to_dir_file.transform_target(target, source)
    return Path.joinpath(target, Location.from_str(source).label .. '.md')
end

return MarkOperation
