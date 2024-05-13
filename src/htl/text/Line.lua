local Line = class()

Line.regex = "^(%s*)(.*)$"
Line.indent_size = 2
Line.name = 'line'

function Line:_init(str)
    self.indent, self.text = self.parse_indent(str)
end

function Line:__tostring()
    return self:string_from_dict(self)
end

function Line:string_from_dict(d)
    return string.format("%s%s", d.indent or "", d.text or "")
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
    local indent, _ = Line.parse_indent(l)
    return indent
end

function Line.get_indent_level(l)
    local indent = Line.get_indent(l)
    return #indent / Line.indent_size
end

function Line:set_indent_level(level)
    self.indent = string.rep(" ", self.indent_size * level)
end

function Line.str_is_a() return true end

function Line:merge(other)
    self.text = self.text:rstrip() .. " " .. other.text:lstrip()
    return self
end

function Line:get_next(text)
    local next = getmetatable(self)(tostring(self))
    next.text = text or ""
    return next
end

function Line:convert_lines(lines)
    return lines:map(function(l)
        return Line(Line:string_from_dict({indent = l.indent, text = l.text}))
    end)
end

function Line.insert_at_pos(l, pos, text)
    l = l or ""
    text = text or ""

    local before = l:sub(1, pos - 1)
    local after = l:sub(pos)

    return before .. text .. after, #before + #text + 1
end

return Line
