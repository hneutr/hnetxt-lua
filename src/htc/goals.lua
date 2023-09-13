local GoalSets = require("htl.goals.set")

return {
    commands = {
        to_close = {
            description = "list past but unclosed goalsets.",
            action = function() GoalSets.to_close():foreach(print) end,
        },
        to_create = {
            description = "list current but empty goalsets.",
            action = function() GoalSets.to_create():foreach(print) end,
        },
    },
}
