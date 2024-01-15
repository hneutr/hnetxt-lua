local NumberedItem = require("htl.text.NeoList.NumberedItem")

describe("parse_sigil", function()
    it("base case", function()
        local l = NumberedItem("1. a")
        assert.are.same("1", l.sigil)
    end)

    it("indented case", function()
        local l = NumberedItem("  2. a")
        assert.are.same("2", l.sigil)
    end)
end)

describe("str_is_a", function()
    it("+: 1 digit", function()
        assert(NumberedItem:str_is_a("1. a"))
    end)

    it("+: multiple digits", function()
        assert(NumberedItem:str_is_a("12. a"))
    end)

    it("+: indent", function()
        assert(NumberedItem:str_is_a("  12. a"))
    end)

    it("+: no text", function()
        assert(NumberedItem:str_is_a("12. "))
    end)

    it("-: 0 digits", function()
        assert.is_false(NumberedItem:str_is_a(". "))
    end)

    it("-: digit but no '.'", function()
        assert.is_false(NumberedItem:str_is_a("1 a"))
    end)
end)
