local Yaml = require("hl.yaml")

local Link = require("htl.text.Link")

local Snippet = class()
Snippet.FIELD_SEPARATOR = ":"

function Snippet:_init(path)
    self.path = path

    self.raw_metadata, self.text = unpack(Yaml.read_document(path, true))

    self.metadata = self:parse(self.raw_metadata)
    self:annotate_universal_fields(self.metadata)

    self.definition = Conf.snippets[self.metadata["is a"]]
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
    return Dict.from_list(
        List.split(raw_metadata, "\n"),
        function(line) return self:parse_line(line) end
    )
end

function Snippet:parse_line(line)
    local key, val

    if line:match(self.FIELD_SEPARATOR) then
        key, val = unpack(line:split(self.FIELD_SEPARATOR, 1))
        key = key:strip()
        val = val:strip()

        if Link:str_is_a(val) then
            val = Snippet(DB.urls:where({id = Link:from_str(val).url}).path)
        end
    else
        key = line
    end

    return key, val
end

--------------------------------------------------------------------------------
--                                                                            --
--                                 inflation                                  --
--                                                                            --
--------------------------------------------------------------------------------
local M = class()

function M:_init(definition_name, args)
    self.definition = Dict(Conf.snippets[definition_name])
    self.lines, self.row = self:inflate_template(self.definition.template, args or {})
end

function M:inflate_template(text, args)
    local row
    local lines = List()
    local regex = "%$%d+$"
    for i, line in ipairs(text:strip():splitlines()) do
        if line:match(regex) then
            local k, v = utils.parsekv(line)
            line = line:gsub(regex, args[k] ~= nil and tostring(args[k]) or "")
            
            if args[k] == nil then
                row = row or i
            end
        end
        
        lines:append(line)
    end
    
    return lines, row or i
end

Snippet.M = M

return Snippet
