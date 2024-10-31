local List = require("hl.List")
local M = require("hl.Dict")

describe("__newindex/__index", function()
    it("nil", function()
        local d = M({a = 1})
        d[nil] = 1

        assert.are.same({a = 1}, d)
    end)

    it("string", function()
        local d = M()
        d.a = 1

        assert.are.same({a = 1}, d)
    end)

    it("list", function()
        local l = List({1, 2})
        local d = M()
        d[l] = 3
        assert.are.same(3, d[l])
    end)
end)

describe("delist", function()
    it("works", function()
        assert.are.same(
            {a = 1, ["1"] = 2},
            M.delist({a = 1, ["1"] = 2, "b"})
        )
    end)
end)

describe("update", function()
    it("number", function()
        assert.are.same(1, M.update(nil, 1))
    end)

    it("table and table, ignores list", function()
        assert.are.same({a = 1, b = 2}, M.update({a = 1}, {b = 2, "c"}))
    end)

    it("table and table", function()
        assert.are.same(
            {a = true, b = true},
            M.update({a = true}, {a = false, b = true})
        )
    end)

    it("simple table", function()
        assert.are.same(
            {a = 1, b = 2, c = -2},
            M.update({a = 1, b = 2}, {a = 0, b = -1, c = -2})
        )
    end)

    it("nested table", function()
        assert.are.same(
            {a = 1, b = 2, c = -2, nested = {z = 100, x = 11}},
            M.update(
                {a = 1, b = 2, nested = {z = 100}},
                {a = 0, b = -1, c = -2, nested = {z = 10, x = 11}}
            )
        )
    end)

    it("double nested table", function()
        assert.are.same(
            {a = 1, b = { b1 = {c = 100}, b2 = {c = 20}, b3 = {c = 22}}},
            M.update(
                {a = 1, b = { b1 = {c = 100}, b2 = {c = 20}}},
                {a = 0, b = { b1 = {c = 10}, b2 = {c = 21}, b3 = {c = 22}}}
            )
        )
    end)
end)

describe("foreachk", function()
    it("works", function()
        local d = M({a = 1, b = 2})
        local l = List()

        d:foreachk(function(k) l:append(k) end)

        assert.are.same({'a', 'b'}, l:sorted())
    end)
end)

describe("foreachv", function()
    it("works", function()
        local d = M({a = 1, b = 2})
        local l = List()

        d:foreachv(function(v) l:append(v) end)

        assert.are.same({1, 2}, l:sorted())
    end)
end)

describe("foreachv", function()
    it("works", function()
        local d = M({a = 1, b = 2})
        local d2 = M({x = 3, y = 4})

        d:foreach(function(k, v) d2[k] = v end)

        assert.are.same({a = 1, b = 2, x = 3, y = 4}, d2)
    end)
end)

describe("transformk", function()
    it("works", function()
        local d = M({["1"] = "a", ["2"] = "b"})

        d:transformk(function(k) return tostring(tonumber(k) * -1) end)

        assert.are.same({["-1"] = "a", ["-2"] = "b"}, d)
    end)
end)

describe("transformv", function()
    it("works", function()
        local d = M({a = 1, b = 2})

        d:transformv(function(v) return v * -1 end)

        assert.are.same({a = -1, b = -2}, d)
    end)
end)

describe("filterv", function()
    it("works", function()
        local d = M({a = 1, b = 2, c = 3})

        d:filterv(function(v) return v ~= 2 end)

        assert.are.same({a = 1, c = 3}, d)
    end)
end)

describe("from_list", function()
    it("works", function()
        assert.are.same(
            M({a = "a val", b = "b val", c = "c val"}),
            M.from_list(
                List({"a", "b", "c"}),
                function(key)
                    return key, key .. " val"
                end
            )
        )
    end)
end)

describe("pop", function()
    it("existing", function()
        local d = M({a = 1})
        assert.are.same(1, d.a)
        assert.are.same(1, d:pop("a"))
        assert.is_nil(d.a)
    end)
    it("non-existing", function()
        local d = M()
        assert.is_nil(d.a)
        assert.is_nil(d:pop("a"))
        assert.is_nil(d.a)
    end)
end)

describe("is_like", function()
    it("-: non-table", function()
        assert.is_false(M.is_like(1))
        assert.is_false(M.is_like("a"))
    end)

    it("-: list", function()
        assert.is_false(M.is_like({1, 2, 3}))
    end)

    it("+: empty table", function()
        assert(M.is_like({}))
    end)

    it("+: key val", function()
        assert(M.is_like({a = 1}))
    end)
end)
