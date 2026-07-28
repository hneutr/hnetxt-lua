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
