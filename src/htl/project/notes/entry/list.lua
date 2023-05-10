local Entry = require("htl.project.notes.entry")

local ListEntry = Entry:extend()
ListEntry.type = 'list'
ListEntry.iterdir_args = {recursive = true, dirs = false}

return ListEntry
