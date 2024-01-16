local class = require("pl.class")
local Dict = require("hl.Dict")
local List = require("hl.List")

local ListConfig = Dict(require("htl.config").get("list"))

local Line = require("htl.text.Line")

class.Item(Line)
Item.sigil_separator = " "
Item.type_configs = Dict(ListConfig.types)
Item.default_type = Item.type_configs[ListConfig.default_type]
Item.sigils = Item.type_configs:values():map(function(c) return c.sigil end):filter(function(s) return s end)

function Item:_init(s)
    self.indent, self.text = self.parse_indent(s)
    self.sigil, self.text = self:parse_sigil(self.text)
    self.name = self:get_name()
end

function Item:get_name()
    for name in self.type_configs:keys():iter() do
        if self.type_configs[name].sigil == self.sigil then
            return name
        end
    end
end

function Item:name_to_sigil(name)
    return self.type_configs[name].sigil
end

function Item:parse_sigil(s)
    s = s:lstrip()
    
    if s:match(string.escape(self.sigil_separator)) then
        local sigil, text = unpack(s:split(self.sigil_separator, 1))
        text = text or ""
        return sigil, text
    end

    return "", s
end

function Item:__tostring()
    return self:string_from_dict(self)
end

function Item:string_from_dict(d)
    return string.format("%s%s%s%s", d.indent or "", d.sigil or "", self.sigil_separator, d.text or "")
end

function Item:str_is_a(s)
    local sigil, _ = self:parse_sigil(s)
    return self.sigils:contains(sigil)
end

function Item:convert_lines(lines, sigil)
    sigil = sigil or self.default_type.sigil
    return lines:map(function(l)
        return Item(Item:string_from_dict({indent = l.indent, sigil = sigil, text = l.text}))
    end)
end

return Item
