local Path = require("hl.path")

local Location = require("htl.text.location")
local Parser = require("htl.parse")

local Operation = require("htl.project.move.operation")

--------------------------------------------------------------------------------
--                               MarkOperation                                --
--------------------------------------------------------------------------------
local M = table.default({}, Operation)

M.check_source = Operation.is_mark

function M.map_mirrors() return {} end

-- this moves source:mark to target (or target:mark, if there is one)
function M.process(map)
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

M.to_dir_file = {}
function M.to_dir_file.transform_target(target, source)
    return Path.joinpath(target, Location.from_str(source).label .. '.md')
end

return M
