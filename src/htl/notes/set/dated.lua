local class = require("pl.class")

local FileSet = require("htl.notes.set.file")
local Blank = require("htl.notes.note.blank")

class.DatedSet(FileSet)

DatedSet.type = 'dated'
DatedSet.today = os.date("%Y%m%d")

function DatedSet:get_path_to_touch(path)
    return FileSet.get_path_to_touch(self, path, {date = true})
end

function DatedSet:path_file(path)
    return Blank(path)
end

return DatedSet
