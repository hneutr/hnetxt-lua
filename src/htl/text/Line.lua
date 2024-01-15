local class = require("pl.class")

class.Line()
Line.regex = "^(%s*)(.*)$"
Line.indent_size = 2

function Line:_init(str)
    self.indent, self.text = self.parse_indent(str)
end

function Line:__tostring()
    return self.indent .. self.text
end

function Line.parse_indent(l)
    if type(l) ~= "string" then
        l = tostring(l)
    end

    local indent, text = l:match(Line.regex)

    indent = indent or ""
    text = text or ""
    return indent, text
end

function Line.get_indent(l)
    local indent, text = Line.parse_indent(l)
    return indent
end

function Line.get_indent_level(l)
    local indent = Line.get_indent(l)
    return #indent / Line.indent_size
end

function Line:set_indent_level(level)
    self.indent = string.rep(" ", self.indent_size * level)
end

function Line.str_is_a(l) return true end

function Line:merge(other)
    self.text = self.text:lstrip() .. " " .. other.text
end

function Line:get_next(text)
    local next = getmetatable(self)(tostring(self))
    next.text = text or "" 
    return next
end

return Line
