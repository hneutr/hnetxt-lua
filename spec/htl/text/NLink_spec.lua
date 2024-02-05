local Links = require("htl.text.NLink")
local Link = Links.Link

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

describe("get_references", function() 
    local dir1 = Path.tempdir:join("test-dir")
    local f1 = dir1:join("file-1.md")
    local f2 = dir1:join("file-2.md")
    local f3 = dir1:join(".file-3.md")

    local r1 = Link({label = "ref1", url = 1})
    local r2 = Link({label = "ref2", url = 2})

    before_each(function()
        dir1:rmdir(true)
    end)

    after_each(function()
        dir1:rmdir(true)
    end)

    it("1 ref", function()
        f1:write({r1})
        assert.are.same(
            {["1"] = {[tostring(f1)] = {1}}},
            Link:get_references(dir1)
        )
    end)

    it("hidden file", function()
        f3:write({r1})
        assert.are.same(
            {["1"] = {[tostring(f3)] = {1}}},
            Link:get_references(dir1)
        )
    end)

    it("2 refs", function()
        f1:write({r1, r2})
        assert.are.same(
            {
                ["1"] = {[tostring(f1)] = {1}},
                ["2"] = {[tostring(f1)] = {2}},
            },
            Link:get_references(dir1)
        )
    end)

    it("2 refs, 1 line", function()
        f1:write(tostring(r1) .. tostring(r2))
        assert.are.same(
            {
                ["1"] = {[tostring(f1)] = {1}},
                ["2"] = {[tostring(f1)] = {1}},
            },
            Link:get_references(dir1)
        )
    end)

    it("multiple files", function()
        f1:write({r1, r2})
        f2:write({r1})

        assert.are.same(
            {
                ["1"] = {
                    [tostring(f1)] = {1},
                    [tostring(f2)] = {1},
                },
                ["2"] = {[tostring(f1)] = {2}},
            },
            Link:get_references(dir1)
        )
    end)
end)
