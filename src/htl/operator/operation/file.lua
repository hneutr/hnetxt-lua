local Path = require('hl.path')

local Mirror = require("htl.project.mirror")
local Location = require("htl.text.location")

local Operation = require('htl.operator.operation')

local M = Dict.from(Operation)
M.type = "file"
M.check_source = Path.is_file

function M.move(map, mirrors_map)
    map = Dict.from(map or {}, mirrors_map or {})

    for source, target in pairs(map) do
        Path.write(target, Path.read(source))
        Path.unlink(source)
    end
end

return M
