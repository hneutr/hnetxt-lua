local htl = require("htl")
local M = require("htl.text.Line")

describe("parse", function()
    
    Dict({
        ["quote + indent + text"] = {
            input = ">   a",
            expected = {quote = "> ", indent = "  ", text = "a"},
        },
        ["short quote + indent + text"] = {
            input = ">  a",
            expected = {quote = ">", indent = "  ", text = "a"},
        },
        ["quote + indent + no text"] = {
            input = ">   ",
            expected = {quote = "> ", indent = "  ", text = ""},
        },
        ["quote + no indent + text"] = {
            input = "> a",
            expected = {quote = "> ", indent = "", text = "a"},
        },
        ["quote + no indent + no text"] = {
            input = "> ",
            expected = {quote = "> ", indent = "", text = ""},
        },
        ["no quote + indent + text"] = {
            input = "  a",
            expected = {quote = "", indent = "  ", text = "a"},
        },
        ["no quote + indent + no text"] = {
            input = "  ",
            expected = {quote = "", indent = "  ", text = ""},
        },
        ["no quote + no indent + text"] = {
            input = "a",
            expected = {quote = "", indent = "", text = "a"},
        },
        ["no quote + no indent + no text"] = {
            input = "",
            expected = {quote = "", indent = "", text = ""},
        },
    }):foreach(function(name, test)
        it(name, function()
            assert.are.same(test.expected, M.parse(test.input))
        end)
    end)
end)

describe("init", function()
    it("parses", function()
        local l = M(">   a")
        assert.are.same({"> ", "  ", "a"}, {l.quote, l.indent, l.text})
    end)
end)

describe("insert_at_pos", function()
    Dict({
        ["add to blank line"] = {input = "|", expected = "+|"},
        ["add at start of line"] = {input = "|abc", expected = "+|abc"},
        ["add at end of line"] = {input = "abc|", expected = "abc+|"},
        ["add at middle of line"] = {input = "abc|def", expected = "abc+|def"},
    }):foreach(function(label, test)
        local link = "[label](url)"
        local input = test.input
        local expected = test.expected

        local test_string = string.format("%s: %s → %s", label, input, expected)

        local input_pos = input:find("|")
        input = input:gsub("|", "")

        expected = expected:gsub("%+", link)
        local expected_pos = expected:find("|")
        expected = expected:gsub("|", "")

        it(test_string, function()
            assert.are.same(
                {expected, expected_pos},
                {M.insert_at_pos(input, input_pos, link)}
            )
        end)
    end)
end)
