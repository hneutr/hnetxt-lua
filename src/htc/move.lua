local Path = require("hl.path")
local Operator = require("htl.operator")

return {
    description = "mv within a project",
    action = function(args) Operator.move(args.source, args.target) end,
    {"source", description = "what to move", args = "1", convert = Path.resolve},
    {"target", description = "where to move it", args = "1", convert = Path.resolve},
}
