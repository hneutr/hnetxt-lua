local Tree = require("hl.Tree")

describe("set", function()
    it("single key", function()
        assert.are.same({a = {}}, Tree():set({'a'}))
    end)

    it("multiple keys", function()
        local t = Tree()
        t:set({'a', 'b'})
        t:set({'a', 'b', 'c'})
        t:set({'a', 'd'})
        assert.are.same({a = {b = {c = {}}, d = {}}}, t)
    end)
end)

describe("prune", function()
    it("1 level tree", function()
        local t = Tree()
        t:set({"a"})
        t:set({"b"})
        assert.are.same(
            List({"a", "b"}),
            t:prune():sorted()
        )
    end)

    it("2 level tree", function()
        local t = Tree()
        t:set({"a", "b"})
        t:set({"c"})
        assert.are.same(
            {a = {"b"}, c = {}},
            t:prune()
        )
    end)
end)

describe("tostring", function()
    it("works", function()
        local t = Tree()
        t:set({"a", "b"})
        t:set({"a", "c", "d"})
        t:set({"e"})

        assert.are.same(
            {
                "a",
                " b",
                " c",
                "  d",
                "e",
            },
            tostring(t):split("\n")
        )
    end)
end)

describe("transform", function()
    it("works", function()
        local t = Tree()
        t:set({"a", "b"})
        t:transform(function(k) return "a" .. k end)
        
        assert.are.same(
            {aa = {ab = {}}},
            t
        )
    end)
end)
