local List = require("hl.List")

describe("init", function()
    it("nil", function()
        assert.are.same({}, List(nil))
    end)
end)

describe("append", function()
    it("works", function()
        local l = List()
        l:append("a")
        l:append("b")

        assert.are.same({"a", "b"}, l)
    end)
    
    it("nil", function()
        local l = List()
        l:append(1)
        l:append(nil)
        l:append(2)
        
        assert.are.same({1, 2}, l)
    end)
end)

describe("extend", function()
    it("works", function()
        local a = {1, 2, 3}
        local b = {4, 5, 6}

        List(a):extend(b)

        assert.are.same({1, 2, 3, 4, 5, 6}, a)
        assert.are.same({4, 5, 6}, b)
    end)

    it("multiple", function()
        assert.are.same({1, 2, 3}, List():extend({1}, {2}, {3}))
    end)

    it("null", function()
        local l = List({1, 2, 3})
        l = l:extend()
        assert.are.same({1, 2, 3}, l)
    end)
end)

describe("from", function()
    it("works", function()
        local a = {1, 2, 3}
        local b = {4, 5, 6}
        local c = List.from(a, b)

        assert.are.same({1, 2, 3}, a)
        assert.are.same({4, 5, 6}, b)
        assert.are.same({1, 2, 3, 4, 5, 6}, c)
    end)
end)

describe("is_listlike", function()
    it("nil: -", function()
        assert.falsy(List.is_listlike())
    end)

    it("dict: -", function()
        assert.falsy(List.is_listlike({a = 1}))
    end)

    it("list: +", function()
        assert(List.is_listlike({1, 2, 3}))
    end)
end)

describe("as_list", function()
    it("already a list", function()
        assert.are.same(List({1, 2, 3}), List.as_list({1, 2, 3}))
    end)

    it("not a list", function()
        assert.are.same(List({1}), List.as_list(1))
    end)

    it("string", function()
        assert.are.same(List({"string"}), List.as_list("string"))
    end)

    it("nil", function()
        assert.are.same(List(), List.as_list(nil))
    end)
end)

describe("all", function()
    it("+", function()
        assert(List({1, "hunter", true}):all())
    end)

    it("-", function()
        assert.falsy(List({1, "hunter", false}):all())
    end)
end)

describe("any", function()
    it("+", function()
        assert(List({false, true}):any())
    end)

    it("-", function()
        assert.falsy(List({false, nil}):any())
    end)
end)
