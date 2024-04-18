require("htl")

local TextList = require("htl.text.List")

local Line = require("htl.text.Line")
local Item = require("htl.text.List.Item")
local NumberedItem = require("htl.text.List.NumberedItem")

describe("parse_line", function()
    it("NumberedItem", function()
        assert(TextList:parse_line("1. a"):is_a(NumberedItem))
    end)

    it("Item", function()
        assert(TextList:parse_line("- a"):is_a(Item))
    end)

    it("defaults to Line", function()
        assert(TextList:parse_line("- a"):is_a(Line))
    end)
end)
