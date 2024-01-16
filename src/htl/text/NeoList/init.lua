local class = require("pl.class")
local List = require("hl.List")

local Line = require("htl.text.Line")
local Item = require("htl.text.NeoList.Item")
local NumberedItem = require("htl.text.NeoList.NumberedItem")

class.NeoList()
NeoList.LineClasses = List({
    NumberedItem,
    Item,
    Line,
})

NeoList.line_class_to_toggle_info = Dict({
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

function NeoList:parse_line(s)
    for Class in self.LineClasses:iter() do
        if Class:str_is_a(s) then
            return Class(s)
        end
    end
end

function NeoList:convert_lines(lines, toggle_line_type_name)
    local lines = List(lines):transform(function(l) return self:parse_line(l) end)
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

return NeoList
