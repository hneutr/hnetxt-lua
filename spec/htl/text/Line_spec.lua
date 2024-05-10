local htl = require("htl")
local Line = require("htl.text.Line")

describe("parse_indent", function()
    it("indent + text", function()
        local indent, text = Line.parse_indent("  a")
        assert.are.same({"  ", "a"}, {indent, text})
    end)
    
    it("indent + no text", function()
        local indent, text = Line.parse_indent("  ")
        assert.are.same({"  ", ""}, {indent, text})
    end)

    it("no indent + text", function()
        local indent, text = Line.parse_indent("a")
        assert.are.same({"", "a"}, {indent, text})
    end)

    it("no indent + no text", function()
        local indent, text = Line.parse_indent("")
        assert.are.same({"", ""}, {indent, text})
    end)
end)

describe("indent_level", function()
    it("indent: 0", function()
        assert.are.same(0, Line.get_indent_level("a"))
    end)
    it("indent: 1", function()
        assert.are.same(1, Line.get_indent_level("  a"))
    end)

    it("indent: 2", function()
        assert.are.same(2, Line.get_indent_level("    a"))
    end)
end)

describe("init", function()
    it("parses", function()
        local l = Line("  a")
        assert.are.same("  ", l.indent)
        assert.are.same("a", l.text)
    end)
end)

describe("set_indent_level", function()
    it("works", function()
        local l = Line("  a")
        assert.are.same(1, l:get_indent_level())
        l:set_indent_level(2)
        assert.are.same(2, l:get_indent_level())
        assert.are.same("    a", tostring(l))
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
                {Line.insert_at_pos(input, input_pos, link)}
            )
        end)
    end)
end)
