table = require("hneutil.table")
string = require("hneutil.string")
local Object = require("hneutil.object")
local Config = require("hnetxt-lua.config")

--------------------------------------------------------------------------------
--                                                                            --
--                                    Line                                    --
--                                                                            --
--------------------------------------------------------------------------------
Line = Object:extend()
Line.defaults = {
    text = '',
    line_number = 0,
    indent = '',
}
Line.regex = "^(%s*)(.*)$"

function Line:new(args)
    self = table.default(self, args or {}, self.defaults)
end

function Line:write()
    BufferLines.set({start_line = self.line_number, replacement = {tostring(self)}})
end

function Line:__tostring()
    return self.indent .. self.text
end

function Line:merge(other)
    self.text = self.text:rstrip() .. " " .. other.text:lstrip()
end

function Line.get_if_str_is_a(str, line_number)
    local indent, text = str:match(Line.regex)
    return Line({text = text, line_number = line_number, indent = indent})
end

--------------------------------------------------------------------------------
--                                  ListLine                                  --
--------------------------------------------------------------------------------
ListLine = Line:extend()
ListLine.defaults = {
    text = '',
    indent = '',
    line_number = 0,
    sigil = '-',
    fold = false,
}

function ListLine:new(args)
    ListLine.super.new(self, args)
end

function ListLine:__tostring()
    return self.indent .. self.sigil .. " " .. self.text
end

function ListLine.get_sigil_pattern(sigil)
    return "^(%s*)" .. string.escape(sigil) .. "%s(.*)$"
end

function ListLine.get_if_str_is_a(str, line_number)
    return ListLine._get_if_str_is_a(str, line_number, ListLine)
end

function ListLine._get_if_str_is_a(str, line_number, ListLineClass)
    local indent, text = str:match(ListLineClass.get_sigil_pattern(ListLineClass.defaults.sigil))
    if indent and text then
        return ListLineClass({text = text, indent = indent, line_number = line_number})
    end
end

function ListLine.get_class(name)
    local settings = Config.get("list").types[name]
    settings.name = name

    local ListClass
    if name == 'number' then
        ListClass = NumberedListLine
    else
        ListClass = ListLine:extend()
    end

    ListClass.defaults = table.default(settings, ListClass.defaults)

    ListClass.get_if_str_is_a = function(str, line_number)
        return ListClass._get_if_str_is_a(str, line_number, ListClass)
    end

    return ListClass
end

--------------------------------------------------------------------------------
--                              NumberedListLine                              --
--------------------------------------------------------------------------------
NumberedListLine = ListLine:extend()
NumberedListLine.pattern = "^(%s*)(%d+)%.%s(.*)$"
NumberedListLine.defaults = table.default({number = 1, ListClass = 'number'}, ListLine.defaults)

function NumberedListLine:__tostring()
    return self.indent .. self.number .. '. ' .. self.text
end

function NumberedListLine._get_if_str_is_a(str, line_number)
    local indent, number, text = str:match(NumberedListLine.pattern)

    if indent and number and text then
        return NumberedListLine({
            number = tonumber(number),
            text = text,
            indent = indent,
            line_number = line_number,
        })
    end
end

--------------------------------------------------------------------------------
--                                   Parser                                   --
--------------------------------------------------------------------------------
Parser = Object:extend()
Parser.default_types = Config.get("list").default_types

function Parser:new(additional_types)
    self.types = table.list_extend({}, self.default_types)

    for _, additional_type in ipairs(additional_types or {}) do
        if not table.list_contains(self.types, additional_type) then
            self.types[#self.types + 1] = additional_type
        end
    end

    self.classes = {}
    for _, type_name in ipairs(self.types) do
        self.classes[type_name] = ListLine.get_class(type_name)
    end
end

function Parser:parse_line(str, line_number)
    for _, Class in pairs(self.classes) do
        local line = Class.get_if_str_is_a(str, line_number)

        if line then
            return line
        end
    end

    return Line.get_if_str_is_a(str, line_number)
end

function Parser:parse(raw_lines)
    self.lines = {}
    for i, line in ipairs(raw_lines) do
        table.insert(self.lines, self:parse_line(line, i))
    end

    return self.lines
end

return {
    Line = Line,
    ListLine = ListLine,
    NumberedListLine = NumberedListLine,
    Parser = Parser,
}

