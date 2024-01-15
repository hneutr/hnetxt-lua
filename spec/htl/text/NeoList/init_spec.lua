local NeoList = require("htl.text.NeoList")

local Line = require("htl.text.Line")
local Item = require("htl.text.NeoList.Item")
local NumberedItem = require("htl.text.NeoList.NumberedItem")


describe("parse_line", function()
    it("NumberedItem", function()
        assert(NeoList:parse_line("1. a"):is_a(NumberedItem))
    end)

    it("Item", function()
        assert(NeoList:parse_line("- a"):is_a(Item))
    end)

    it("defaults to Line", function()
        assert(NeoList:parse_line("- a"):is_a(Line))
    end)
end)
