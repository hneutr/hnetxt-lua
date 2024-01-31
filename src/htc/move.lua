local Path = require("hl.path")
local Operator = require("htl.operator")
local Move = require("htl.move")

return {
    description = "mv within a project",
    {"source", description = "what to move", args = "1", convert = Path.resolve},
    {"target", description = "where to move it", args = "1", convert = Path.resolve},
    action = function(args)
        -- Move(args.source, args.target)
        Operator.move(args.source, args.target)
    end,
}
