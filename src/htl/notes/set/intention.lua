local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local Config = require("htl.config")
local Fields = require("htl.notes.field")

local FileSet = require("htl.notes.set.file")
local File = require("htl.notes.note.file")
local Statement = require("htl.notes.note.statement")

class.IntentionSet(FileSet)

IntentionSet.type = 'intention'
IntentionSet.dir_file = Config.get("directory_file")
IntentionSet.defaults = {
    fields = {
        start = {},
        date = false,
        ["end"] = '',
        goal_type = "day",
        goal = "s: t [q]{p}",
    },
}

function IntentionSet.format(set)
    set.fields = Fields.format(Dict.update(set.fields, IntentionSet.defaults.fields))
    return set
end


return IntentionSet
