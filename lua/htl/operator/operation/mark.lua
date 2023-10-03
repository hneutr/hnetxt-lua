local Dict = require("hl.Dict")
local Path = require("hl.Path")

local Location = require("htl.text.location")
local Parser = require("htl.parse")

local Operation = require('htl.operator.operation')

local M = Dict.from(Operation)
M.type = "mark"
M.check_source = Operation.is_mark

function M.map_mirrors() return {} end

-- this moves source:mark to target (or target:mark, if there is one)
function M.move(map)
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

function M.remove(source)
    Parser():remove_mark_content(Location.from_str(source))
end

M.to_dir_file = {}
function M.to_dir_file.transform_target(target, source)
    return Path.join(target, Location.from_str(source).label .. '.md')
end

return M
