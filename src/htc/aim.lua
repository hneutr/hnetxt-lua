local Config = require("htl.config")

return {
    description = "return the path to a goals set",
    action = function()
        print(require("htl.goals")())
    end,
}
