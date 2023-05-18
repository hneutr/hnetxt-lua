local class = require("pl.class")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Fields = require("htl.notes.field")

class.File()

function File:_init(path, fields)
    self.path = path
    self.fields = Fields.get(fields)
end

function File:write(metadata, content)
    content = content or ""
    Yaml.write_document(self.path, metadata, content)
end

function File:read()
    local metadata, content = {}, ""

    if Path.exists(self.path) then
        metadata, content = unpack(Yaml.read_document(self.path))
    end

    return {metadata, content}
end

function File:touch(metadata)
    if not Path.exists(self.path) then
        self:write(Fields.set_metadata(self.fields, metadata))
    end
end

function File:get_metadata()
    return self:read()[1]
end

function File:set_metadata(new_metadata)
    local metadata, content = unpack(self:read())

    metadata = Fields.set_metadata(self.fields, Dict(new_metadata, metadata))

    self:write(metadata, content)
end

return File
