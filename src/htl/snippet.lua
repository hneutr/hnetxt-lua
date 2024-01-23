local List = require("hl.List")
local Path = require("hl.Path")
local Link = require("htl.text.link")
local Dict = require("hl.Dict")
local class = require("pl.class")
local Yaml = require("hl.yaml")

local db = require("htl.db")

class.Snippet()
Snippet.definitions = require("htl.config").get_dir("snippets")
Snippet.FIELD_SEPARATOR = ":"

function Snippet:_init(path)
    self.path = path

    self.raw_metadata, self.text = unpack(Yaml.read_document(path, true))

    self.metadata = self:parse(self.raw_metadata)
    self:annotate_universal_fields(self.metadata)

    self.definition = self.definitions[self.metadata["is a"]]
end

function Snippet:annotate_universal_fields(metadata)
    metadata["__text__"] = self.text
    metadata["__stem__"] = self.path:stem()
end

function Snippet:__tostring()
    if not self.definition then
        return self.text:split("\n")[1]
    end

    local str = self.definition.string

    local parts = List()
    for key in str:gmatch("{(.-)}") do
        local value = self.metadata[key]

        if value == nil then
            value = ""
        end

        str = str:gsub("{" .. key .. "}", tostring(value))
    end
    
    str = str:gsub("  ", " ")

    return str:strip()
end

function Snippet:parse(raw_metadata)
    local metadata = Dict()
    List.split(raw_metadata, "\n"):foreach(function(line)
        local field, value = self:parse_line(line)
        metadata[field] = value
    end)
    return metadata
end

function Snippet:parse_line(line)
    local field, value

    if line:match(":") then
        field, value = unpack(line:split(":", 1))
        field = field:strip()
        value = value:strip()

        if Link.str_is_a(value) then
            value = Snippet(db.get()['projects'].get_path(self.path):join(Link.from_str(value).location))
        end
    else
        field = line
    end

    return field, value
end

return Snippet
