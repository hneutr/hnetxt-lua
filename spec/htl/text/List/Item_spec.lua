require("htl")

local Item = require("htl.text.List.Item")

describe("parse_sigil", function()
    it("base case", function()
        local l = Item("- a")
        assert.are.same("-", l.sigil)
    end)

    it("indented case", function()
        local l = Item("  - a")
        assert.are.same("-", l.sigil)
    end)
end)

describe("str_is_a", function()
    it("+", function()
        assert(Item:str_is_a("- a"))
        assert(Item:str_is_a("? a"))
        assert(Item:str_is_a("* a"))
    end)
    
    it("+: indent", function()
        assert(Item:str_is_a("  - a"))
    end)

    it("+: no text", function()
        assert(Item:str_is_a("- "))
    end)

    it("-: bad sigil", function()
        assert.is_false(Item:str_is_a("1. "))
    end)
end)

describe("convert_lines", function()
    it("works", function()
        local original = List({
            Item("! a"),
            Item("  ~ b"),
            Item("    - c")
        })

        local converted = 
        assert.are.same(
            List({
                Item("? a"),
                Item("  ? b"),
                Item("    ? c")
            }),
            Item:convert_lines(original, "?")
        )
    end)
end)

describe("get_name", function()
    it("works", function()
        assert.are.same("bullet", Item("- a").name)
        assert.are.same("important", Item("! a").name)
    end)
end)
