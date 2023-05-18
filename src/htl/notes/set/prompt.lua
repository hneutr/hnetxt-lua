local class = require("pl.class")
local Dict = require("hl.Dict")

local TopicSet = require("htl.notes.set.topic")

class.PromptSet(TopicSet)

PromptSet.type = 'question'
PromptSet.defaults = {
    statement = {
        fields = {open = true},
        filters = {open = true},
    },
    file = {
        fields = {pinned = false},
        filters = {},
    },
}

function PromptSet.format(set)
    set = set or {}
    set.statement = Dict(set.statement, PromptSet.defaults.statement)
    set.file = Dict(set.file, PromptSet.defaults.file)
    return TopicSet.format(set)
end

return PromptSet
