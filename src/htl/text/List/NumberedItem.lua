local class = require("pl.class")
local Item = require("htl.text.List.Item")

class.NumberedItem(Item)
NumberedItem.sigil_separator = ". "

function NumberedItem:str_is_a(s)
    local sigil, _ = self:parse_sigil(s)

    if sigil:match("%d+") then
        return true
    end

    return false
end

function NumberedItem:get_name()
    return "number"
end

function NumberedItem:get_next(text)
    local next = getmetatable(self)(tostring(self))
    next.text = text or "" 
    next.sigil = tonumber(self.sigil) + 1
    return next
end

function NumberedItem:convert_lines(lines)
    local indent_to_last_index = Dict()
    return lines:map(function(l)
        if not indent_to_last_index[l.indent] then
            indent_to_last_index[l.indent] = 0
        end

        indent_to_last_index[l.indent] = indent_to_last_index[l.indent] + 1

        indent_to_last_index:filterk(function(indent)
            return #indent <= #l.indent
        end)

        return NumberedItem(
            NumberedItem:string_from_dict({
                indent = l.indent,
                sigil = indent_to_last_index[l.indent],
                text = l.text
            })
        )
    end)
end

return NumberedItem
