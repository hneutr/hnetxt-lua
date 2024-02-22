local Set = require("hl.Set")

describe("vals", function()
    it("works", function()
        assert.are.same({1, 2, 3}, Set({1, 2, 3}):vals())
    end)
end)

describe("has", function()
    it("has", function()
        assert(Set({1}):has(1))
    end)
    
    it("doesn't have", function()
        assert.is_false(Set({1}):has(2))
    end)
end)

describe("union", function()
    it("set:union(set)", function()
        assert.are.same(
            Set({1, 2, 3}),
            Set({1, 2}):union(Set({1, 3}))
        )
    end)
    
    it("set + set", function()
        assert.are.same(
            Set({1, 2, 3}),
            Set({1, 2}) + Set({1, 3})
        )
    end)

    it("set + non-list", function()
        assert.are.same(
            Set({1, 2, 3}),
            Set({1, 2}) + 3
        )
    end)

    it("set + table", function()
        assert.are.same(
            Set({1, 2, 3}),
            Set({1, 2}) + {2, 3}
        )
    end)

    it("set + list", function()
        assert.are.same(
            Set({1, 2, 3}),
            Set({1, 2}) + List({2, 3})
        )
    end)
end)

describe("intersection", function()
    it("set:intersection(set)", function()
        assert.are.same(Set({2, 3}), Set({1, 2, 3}):intersection(Set{2, 3, 4}))
    end)
    
    it("set * set", function()
        assert.are.same(Set({2, 3}), Set({1, 2, 3}) * Set{2, 3, 4})
    end)
end)

describe("difference", function()
    it("set:difference(set)", function()
        assert.are.same(Set({1}), Set({1, 2, 3}):difference(Set{2, 3, 4}))
    end)
    
    it("set - set", function()
        assert.are.same(Set({1}), Set({1, 2, 3}) - Set{2, 3, 4})
    end)
end)

describe("symmetric_difference", function()
    it("set:symmetric_difference(set)", function()
        assert.are.same(Set({1, 4}), Set({1, 2, 3}):symmetric_difference(Set{2, 3, 4}))
    end)
    
    it("set ^ set", function()
        assert.are.same(Set({1, 4}), Set({1, 2, 3}) ^ Set{2, 3, 4})
    end)
end)

describe("issubset", function()
    it("set:issubset(set): +", function()
        assert(Set({1, 2}):issubset(Set{1, 2, 3}))
    end)
    
    it("set < set: +", function()
        assert(Set({1, 2}) < Set{1, 2, 3})
    end)

    it("set:issubset(set): -", function()
        assert.falsy(Set({1, 2, 3}):issubset(Set{1, 2}))
    end)
    
    it("set < set: -", function()
        assert.falsy(Set({1, 2, 3}) < Set{1, 2})
    end)
end)

describe("len", function()
    it("works", function()
        assert.are.same(2, Set({1, 2}):len())
    end)
end)

describe("equals", function()
    it("set == set: +", function()
        assert(Set({1, 2}) == Set({1, 2}))
    end)
    
    it("set == set: -", function()
        assert.falsy(Set({1, 2}) == Set({1, 2, 3}))
    end)
end)

describe("isempty", function()
    it("+", function()
        assert(Set():isempty())
    end)
    
    it("-", function()
        assert.falsy(Set({1, 2}):isempty())
    end)
end)

describe("isdisjoint", function()
    it("+", function()
        assert(Set({1}):isdisjoint(Set({2})))
    end)
    
    it("-", function()
        assert.falsy(Set({1}):isdisjoint(Set({1, 2})))
    end)
end)

describe("add", function()
    it("set:add(element)", function()
        local set = Set({1})
        set:add(2)
        assert.are.same(Set({1, 2}), set)
    end)
    
    it("set:add(set)", function()
        local set = Set({1})
        set:add(Set({2}))
        assert.are.same(Set({1, 2}), set)
    end)

    it("set + list", function()
        local set = Set({1})
        set:add({2})
        assert.are.same(Set({1, 2}), set)
    end)
end)
