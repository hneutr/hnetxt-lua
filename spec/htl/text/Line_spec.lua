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
