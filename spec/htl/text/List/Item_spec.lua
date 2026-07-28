require("htl")

local M = require("htl.text.List.Item")

describe("parse_sigil", function()
    Dict({
        basic = {input = "- a", expected = "-"},
        indent = {input = "  - a", expected = "-"},
        quote = {input = "> - a", expected = "-"},
        ["quote and indented"] = {input = ">   - a", expected = "-"},
    }):foreach(function(name, test)
        it(name, function()
            assert.are.same(test.expected, M(test.input).sigil)
        end)
    end)
end)

describe("str_is_a", function()
    Dict({
        dash = {input = "- a", expected = true},
        dot = {input = "* a", expected = true},
        indented = {input = "  - a", expected = true},
        ["no text"] = {input = "- ", expected = true},
        ["bad sigil"] = {input = "1. ", expected = false},
        quote = {input = "> - a", expected = true},
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
                "- a",
                "  - b",
                "    - c"
            },
            M.transform(
                List({
                    M("* a"),
                    M("  - [~] b"),
                    M("    - c")
                }),
                "-"
            ):transform(M.__tostring)
        )
    end)
end)
