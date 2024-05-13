local Line = require("htl.text.Line")
local Item = require("htl.text.List.Item")
local NumberedItem = require("htl.text.List.NumberedItem")

local TextList = class()
TextList.LineClasses = List({
    NumberedItem,
    Item,
    Line,
})

TextList.line_class_to_toggle_info = Dict({
    number = {
        on = NumberedItem,
        off = Item,
    },
    bullet = {
        on = Item,
        off = Line,
    },
    line = {
        on = Line,
        off = Item,
    },
    other = {
        on = Item,
        off = Item,
    }
})

function TextList:parse_line(s)
    for Class in self.LineClasses:iter() do
        if Class:str_is_a(s) then
            return Class(s)
        end
    end
end

function TextList:convert_lines(lines, toggle_line_type_name)
    lines = List(lines):transform(function(l) return self:parse_line(l) end)
    local outmost_line = lines:sorted(function(a, b) return #a.indent < #b.indent end)[1]

    local toggle_info = self.line_class_to_toggle_info[toggle_line_type_name]
    toggle_info = toggle_info or self.line_class_to_toggle_info.other

    local toggle
    local sigil
    if outmost_line.name == toggle_line_type_name then
        toggle = 'off'
    else
        toggle = 'on'
        sigil = Item:name_to_sigil(toggle_line_type_name)
    end

    return toggle_info[toggle]:convert_lines(lines, sigil)
end

return TextList
