require("htl")

local M = require("htl.text.List")

local Line = require("htl.text.Line")
local Item = require("htl.text.List.Item")
local NumberedItem = require("htl.text.List.NumberedItem")

describe("parse", function()
    Dict({
        NumberedItem = {input = "1. a", expected = NumberedItem},
        Item = {input = "- a", expected = Item},
        Line = {input = "a", expected = Line},
    }):foreach(function(name, test)
        assert(M.parse(test.input):is_a(test.expected))
    end)
end)
