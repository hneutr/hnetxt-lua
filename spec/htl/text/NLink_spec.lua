local Links = require("htl.text.NLink")
local Link = Links.Link
local DefinitionLink = Links.DefinitionLink

describe("Link", function()
    describe("str_is_a", function() 
        it("+: []()", function()
            assert.is_truthy(Link:str_is_a("[]()"))
        end)

        it("+: a[b](c)d", function()
            assert.is_truthy(Link:str_is_a("a[b](c)d"))
        end)

        it("-: [] ()", function()
            assert.is_falsy(Link:str_is_a("[] ()"))
        end)
    end)

    describe("__tostring", function() 
        it("works", function()
            local str = "a[b](c)d"
            assert.are.same(str, tostring(Link:from_str(str)))
        end)
    end)
end)

describe("DefinitionLink", function()
    describe("str_is_a", function() 
        it("+: [](:a:)", function()
            assert.is_truthy(DefinitionLink:str_is_a("[](:a:)"))
        end)

        it("+: a[b](:c:)d", function()
            assert.is_truthy(DefinitionLink:str_is_a("a[b](:c:)d"))
        end)

        it("-: []()", function()
            assert.is_falsy(DefinitionLink:str_is_a("[]()"))
        end)

        it("-: [] (:a:)", function()
            assert.is_falsy(DefinitionLink:str_is_a("[] (:a:)"))
        end)
    end)

    describe("__tostring", function() 
        it("works", function()
            local str = "a[b](:c:)d"
            assert.are.same(str, tostring(DefinitionLink:from_str(str)))
        end)

        it("modifying url", function()
            local l = DefinitionLink:from_str("[a](:b:)")
            l.url = "x"
            assert.are.same("[a](:x:)", tostring(l))
        end)
    end)
end)
