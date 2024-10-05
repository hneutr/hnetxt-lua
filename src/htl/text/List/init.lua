local Line = require("htl.text.Line")
local Item = require("htl.text.List.Item")
local NumberedItem = require("htl.text.List.NumberedItem")

local M = {}
M.ItemTypes = List({
    NumberedItem,
    Item,
    Line,
})

M.toggle_info = {
    number = {
        on = NumberedItem,
    },
    bullet = {
        off = Line,
    },
}

function M.parse(s)
    for ItemType in M.ItemTypes:iter() do
        if ItemType.str_is_a(s) then
            return ItemType(s)
        end
    end
end

function M.merge(lines)
    return lines:transform(M.parse):reduce(function(a, b)
        a.text = a.text:rstrip() .. " " .. b.text:lstrip()
        return a
    end)
end

function M.change_quote(lines, outer_line)
    local old = outer_line.quote or ""
    local new = old:startswith(">") and "" or "> "
    return lines:transform(function(l)
        l.quote = new
        return tostring(l)
    end)
end

function M.change_type(lines, outer_line, change_type)
    local direction, sigil

    if outer_line.conf.name == change_type then
        direction = 'off'
    else
        direction = 'on'
        sigil = Item.get_conf("name", change_type).sigil
    end
    
    local toggle_info = M.toggle_info[change_type] or {}
    local Toggler = toggle_info[direction] or Item
    
    return Toggler.transform(lines, sigil):transform(Toggler.__tostring)
end

function M.change_indent(lines, direction)
    return lines:transform(function(l)
        local indent = l.indent or ""

        if direction == 1 then
            indent = indent .. "  "
        else
            indent = indent:sub(3)
        end
        
        l.indent = indent
        
        return tostring(l)
    end)
end

function M.change(lines, change_type, direction)
    lines = lines:transform(M.parse)

    local outer_line = lines:sorted(function(a, b) return #a.indent < #b.indent end)[1]
    
    if change_type == 'quote' then
        return M.change_quote(lines, outer_line)
    elseif change_type == 'indent' then
        return M.change_indent(lines, direction)
    else
        return M.change_type(lines, outer_line, change_type)
    end
end

return M
