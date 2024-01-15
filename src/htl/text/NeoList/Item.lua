local class = require("pl.class")
local Line = require("htl.text.Line")
local Dict = require("hl.Dict")

class.Item(Line)
Item.sigil_separator = " "
Item.type_configs = Dict(require("htl.config").get("list").types)
Item.sigils = Item.type_configs:values():map(function(c) return c.sigil end):filter(function(s) return s end)

function Item:_init(s)
    self.indent, self.text = self.parse_indent(s)
    self.sigil, self.text = self:parse_sigil(self.text)
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
    return self.indent .. self.sigil .. self.sigil_separator .. self.text
end

function Item:str_is_a(s)
    local sigil, _ = self:parse_sigil(s)
    return self.sigils:contains(sigil)
end

return Item
