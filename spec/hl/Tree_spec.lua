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

describe("pop", function()
    it("non-existing", function()
        local t = Tree({a = {}})
        assert.is_nil(t:pop("b"))
        assert.are.same(Tree({a = {}}), t)
    end)
    
    it("existing", function()
        local t = Tree({a = {}, b = {c = {}}})
        assert.are.same(Tree({c = {}}), t:pop("b"))
        assert.are.same(Tree({a = {}}), t)
    end)
end)

describe("get", function()
    it("exists", function()
        local t = Tree({a = {b = {c = {}}}})
        local c = t:get("c")
        assert.are.equal(t.a.b.c, c)

        c.x = 1
        
        assert.are.same({x = 1}, t:get("c"))
    end)
end)

describe("add", function()
    it("existing key", function()
        local t = Tree({a = {b = {c = {}}}})
        t:add(Tree({
            a = {
                b = {
                    d = {}
                },
                e = {}
            }
        }))
        assert.are.same({b = {c = {}, d = {}}, e = {}}, t:get("a"))
    end)

    it("missing key", function()
        local t = Tree({a = {b = {c = {}}}})
        t:add(Tree({
            e = {}
        }))
        assert.are.same({}, t:get("e"))
    end) 
end)

describe("add_edge", function()
    it("new source, new target", function()
        assert.are.same(
            Tree({a = {b = {}}}),
            Tree():add_edge("a", "b")
        )
    end)

    it("new source, existing target", function()
        assert.are.same(
            Tree({a = {b = {c = {}}}}),
            Tree({b = {c = {}}}):add_edge("a", "b")
        )
    end)
    
    it("existing source, new target", function()
        assert.are.same(
            Tree({a = {b = {}, c = {}}}),
            Tree({a = {b = {}}}):add_edge("a", "c")
        )
    end)
    
    it("existing source, existing target", function()
        assert.are.same(
            Tree({a = {b = {}}}),
            Tree({a = {b = {}}}):add_edge("a", "b")
        )
    end)

    it("no target", function()
        assert.are.same(
            Tree({a = {}}),
            Tree():add_edge("a")
        )
    end)

    it("no subject", function()
        assert.are.same(
            Tree({b = {}}),
            Tree():add_edge(nil, "b")
        )
    end)
end)

describe("parents", function()
    it("works", function()
        local t = Tree({a = {b = {c = {}, d = {}}}})
        assert.are.same({b = "a", c = "b", d = "b"}, t:parents())
    end)
end)

describe("children", function()
    it("direct", function()
        local t = Tree({a = {b = {c = {}, d = {}}}})
        assert.are.same({a = {"b"}, b = {"c", "d"}, c = {}, d = {}}, t:children())
    end)
end)

describe("descendants", function()
    it("works", function()
        local t = Tree({a = {b = {c = {}, d = {}}}})
        assert.are.same({a = {"b", "c", "d"}, b = {"c", "d"}, c = {}, d = {}}, t:descendants())
    end)
end)

describe("ancestors", function()
    it("works", function()
        local t = Tree({a = {b = {c = {}, d = {}}}})
        assert.are.same({d = {"b", "a"}, c = {"b", "a"}, b = {"a"}, a = {}}, t:ancestors())
    end)
end)

describe("generations", function()
    it("works", function()
        local t = Tree({a = {b = {c = {}, d = {}}}})
        assert.are.same({a = 1, b = 2, c = 3, d = 3}, t:generations())
    end)
end)
