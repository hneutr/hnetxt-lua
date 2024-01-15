local class = require("pl.class")
local Item = require("htl.text.NeoList.Item")

class.NumberedItem(Item)
NumberedItem.sigil_separator = ". "

function NumberedItem:str_is_a(s)
    local sigil, _ = self:parse_sigil(s)

    if sigil:match("%d+") then
        return true
    end

    return false
end

function NumberedItem:get_next(text)
    local next = getmetatable(self)(tostring(self))
    next.text = text or "" 
    next.sigil = tonumber(self.sigil) + 1
    return next
end


return NumberedItem
