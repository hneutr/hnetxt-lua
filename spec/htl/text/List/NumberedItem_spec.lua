require("htl")

local Item = require("htl.text.List.Item")
local M = require("htl.text.List.NumberedItem")

describe("parse_sigil", function()
    it("base case", function()
        assert.are.same("1", M("1. a").sigil)
    end)

    it("indented case", function()
        assert.are.same("2", M("  2. a").sigil)
    end)
end)

describe("str_is_a", function()
    Dict({
        digit = {input = "1. a", expected = true},
        digits = {input = "12. a", expected = true},
        indent = {input = "  12. a", expected = true},
        ["no text"] = {input = "12. ", expected = true},
        ["0 digits"] = {input = ". ", expected = false},
        ["no dot"] = {input = "1 a", expected = false},
        ["digit not immediately followed by a period"] = {input = "2 a.", expected = false},
        ["digit not at start"] = {input = "  a2. b", expected = false},
    }):foreach(function(name, test)
        it(name, function()
            assert.are.same(test.expected, M.str_is_a(test.input))
        end)
    end)
end)

describe("convert_lines", function()
    it("works", function()
        assert.are.same(
            {
                "1. a",
                "  1. b",
                "    1. c",
                "    2. d",
                "  2. e",
                "    1. f",
                "    2. g",
                "2. h",
                "3. i",
            },
            M.transform(List({
                Item("* a"),
                Item("  ~ b"),
                Item("    - c"),
                Item("    - d"),
                Item("  ~ e"),
                Item("    - f"),
                Item("    - g"),
                Item("- h"),
                Item("* i")
            })):transform(M.__tostring)
        )
    end)
end)
