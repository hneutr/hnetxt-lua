local List = require("hl.List")

-- print(require("inspect")(require("pl.List")))
-- print(require("inspect")(List))

describe("append", function()
    it("works", function()
        local l = List()
        l:append("a")
        l:append("b")

        assert.are.same({"a", "b"}, l)
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
