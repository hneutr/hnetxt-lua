string = require("hl.string")
io = require("hl.io")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local Object = require("hl.object")
local Config = require("htl.config")

--------------------------------------------------------------------------------
--                                                                            --
--                                    Line                                    --
--                                                                            --
--------------------------------------------------------------------------------
LLine = Object:extend()
LLine.defaults = {
    text = '',
    line_number = 0,
    indent = '',
}
LLine.indent_size = 2
LLine.regex = "^(%s*)(.*)$"

function LLine:new(args)
    self = Dict.update(self, args or {}, self.defaults)
end

function LLine:__tostring()
    return self.indent .. self.text
end

function LLine:merge(other)
    self.text = self.text:rstrip() .. " " .. other.text:lstrip()
end

function LLine.get_if_str_is_a(str, line_number)
    local indent, text = str:match(LLine.regex)
    return LLine({text = text, line_number = line_number, indent = indent})
end

function LLine:indent_level()
    return self.indent:len() / self.indent_size
end

--------------------------------------------------------------------------------
--                                  ListLine                                  --
--------------------------------------------------------------------------------
ListLine = LLine:extend()
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

    ListClass.defaults = Dict.update(settings, ListClass.defaults)

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
NumberedListLine.defaults = Dict.from({number = 1, ListClass = 'number'}, ListLine.defaults)

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
    self.types = List.from(self.default_types)

    for _, additional_type in ipairs(additional_types or {}) do
        if not self.types:contains(additional_type) then
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

    return LLine.get_if_str_is_a(str, line_number)
end

function Parser:parse(raw_lines)
    self.lines = List()
    for i, line in ipairs(raw_lines) do
        self.lines:append(self:parse_line(line, i))
    end

    return self.lines
end

function Parser.get_instances(list_type, dir)
    local config = Config.get("list").types[list_type]
    local regex_sigil = config.rg_regex or config.sigil_regex or config.sigil
    local command = [[rg --no-heading --line-number "^\s*]] .. regex_sigil .. [[\s+" ]] .. dir

    local ListClass = ListLine.get_class(list_type)
    local instances = {}
    for _, result in ipairs(io.command(command):splitlines()) do
        if #result > 0 then
            local path, line_number, text = result:match("(.-)%.md%:(%d+)%:%s*(.*)")
            path = Path.relative_to(path, dir)
            text = ListClass.get_if_str_is_a(text).text

            if not instances[path] then
                instances[path] = List()
            end

            instances[path]:append({line_number = tonumber(line_number), text = text})
        end
    end

    return instances
end


return {
    Line = LLine,
    ListLine = ListLine,
    NumberedListLine = NumberedListLine,
    Parser = Parser,
}
