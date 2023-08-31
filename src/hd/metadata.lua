local Path = require("hl.path")
local List = require("hl.List")
local Dict = require("hl.Dict")
local uuid = require("hd.uuid")
local Divider = require('htl.text.divider')
local Link = require('htl.text.link')

local class = require("pl.class")

class.Metadata()

Metadata.link_char = "!"
Metadata.default_label = "title"
Metadata.fields = List({"is a", "of"})
Metadata.defaults = {size = "large"}
Metadata.tab = "  "

function Metadata:_init(args)
    self = Dict.update(self, args or {}, self.defaults)
    self.uuid = uuid()
    self.path = Path.joinpath(Path.cwd(), self.uuid .. ".md")
    self.divider = Divider(self.size)
end

function Metadata:get_field_strings()
    return self.fields:map(function(field)
        return self.tab .. field .. ": "
    end)
end

function Metadata:write()
    Path.write(self.path, tostring(self))
end

function Metadata:__tostring()
    local divider = Divider.dividers_by_size()[self.size]
    local link = Link({location = self.uuid, label = self.default_label})

    local lines = List({
        tostring(divider),
        self.link_char .. tostring(link) .. ":",
    })

    for _, field in ipairs(self.fields) do
        lines:append(self.tab .. field .. ": ")
    end

    lines:append(tostring(divider))

    return lines:join("\n")
end

function Metadata:snippet_components()
    return List.from(
        {
            tostring(self.divider),
            self.link_char .. "[",
            "INPUT:" .. self.default_label,
            "](",
            uuid,
            "):"
        },
        self:get_field_strings(),
        {tostring(self.divider)}
    )
end

return Metadata
