local Item = require("htl.text.List.Item")

local M = class(Item)
M.name = "number"

function M.parse(str)
    local p = Item.parse(str)

    p.sigil, p.text = p.text:match("^(%d+)%.%s(.*)")
    p.conf = M.get_conf("name", "number")
    
    return p
end

function M.str_is_a(s)
    return M.parse(s).sigil and true or false
end

function M:__tostring()
    return List({
        self.quote,
        self.indent,
        self.sigil,
        ". ",
        self.text,
    }):join()
end

function M:get_next(text)
    local next = Item.get_next(self, text)
    next.sigil = tonumber(self.sigil) + 1
    return next
end

function M.transform(lines)
    local indent_to_n = Dict()
    return lines:transform(function(l)
        if not indent_to_n[l.indent] then
            indent_to_n[l.indent] = 0
        end

        indent_to_n[l.indent] = indent_to_n[l.indent] + 1
        indent_to_n:filterk(function(indent) return #indent <= #l.indent end)
        l.sigil = indent_to_n[l.indent]
        return l
    end)
end

return M
