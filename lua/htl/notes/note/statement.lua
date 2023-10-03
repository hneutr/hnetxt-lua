local class = require("pl.class")
local Path = require("hl.path")
local File = require("htl.notes.note.file")

class.Statement(File)
Statement.type = 'statement'

function Statement:get_name()
    return Path.name(Path.parent(self.path))
end

function Statement:get_stem()
    return Path.stem(Path.parent(self.path))
end

function Statement:get_set_path()
    return Path.parent(Path.parent(self.path))
end

return Statement
