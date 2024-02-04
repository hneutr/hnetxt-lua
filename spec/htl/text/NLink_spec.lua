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

    describe("get_nearest", function()
        it("1 link: cursor in link", function()
            local l = "a [b](c) d"
            assert.are.same("c", Link:get_nearest(l, l:find("b")).url)
        end)

        it("1 link: cursor before link", function()
            local l = "a [b](c) d"
            assert.equal("c", Link:get_nearest(l, l:find("a")).url)
        end)

        it("1 link: cursor after link", function()
            local l = "a [b](c) d"
            assert.equal("c", Link:get_nearest(l, l:find("d")).url)
        end)

        it("2 links: cursor before link 1", function()
            local l = "a [b](c) d [e](f) g"
            assert.equal("c", Link:get_nearest(l, l:find("a")).url)
        end)

        it("2 links: cursor in link 1", function()
            local l = "a [b](c) d [e](f) g"
            assert.equal("c", Link:get_nearest(l, l:find("b")).url)
        end)

        it("2 links: cursor in between links", function()
            local l = "a [b](c) d [e](f) g"
            assert.equal("c", Link:get_nearest(l, l:find("d")).url)
        end)

        it("2 links: cursor in link 2", function()
            local l = "a [b](c) d [e](f) g"
            assert.equal("f", Link:get_nearest(l, l:find("e")).url)
        end)

        it("2 links: cursor in after link 2", function()
            local l = "a [b](c) d [e](f) g"
            assert.equal("f", Link:get_nearest(l, l:find("g")).url)
        end)

        it("3 links: cursor between link 2 and 3", function()
            local l = "a [b](c) d [e](f) g [h](i) j"
            assert.equal("f", Link:get_nearest(l, l:find("g")).url)
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
