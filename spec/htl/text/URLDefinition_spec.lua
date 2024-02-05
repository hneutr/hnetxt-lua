local URLDefinition = require("htl.text.URLDefinition")

describe("str_is_a", function() 
    it("+: [](:a:)", function()
        assert.is_truthy(URLDefinition:str_is_a("[](:a:)"))
    end)

    it("+: a[b](:c:)d", function()
        assert.is_truthy(URLDefinition:str_is_a("a[b](:c:)d"))
    end)

    it("-: []()", function()
        assert.is_falsy(URLDefinition:str_is_a("[]()"))
    end)

    it("-: [] (:a:)", function()
        assert.is_falsy(URLDefinition:str_is_a("[] (:a:)"))
    end)
end)

describe("__tostring", function() 
    it("works", function()
        local str = "a[b](:c:)d"
        assert.are.same(str, tostring(URLDefinition:from_str(str)))
    end)

    it("modifying url", function()
        local l = URLDefinition:from_str("[a](:b:)")
        l.url = "x"
        assert.are.same("[a](:x:)", tostring(l))
    end)
end)
