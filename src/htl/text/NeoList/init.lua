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

function NeoList:parse_line(s)
    for Class in self.LineClasses:iter() do
        if Class:str_is_a(s) then
            return Class(s)
        end
    end
end

return NeoList
