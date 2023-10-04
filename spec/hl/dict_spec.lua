local Dict = require("hl.Dict")
local List = require("hl.List")

describe("delist", function()
    it("works", function()
        assert.are.same(
            {a = 1, ["1"] = 2},
            Dict.delist({a = 1, ["1"] = 2, "b"})
        )
    end)
end)

describe("update", function()
    it("number", function()
        assert.are.same(1, Dict.update(nil, 1))
    end)

    it("table and table, ignores list", function()
        assert.are.same({a = 1, b = 2}, Dict.update({a = 1}, {b = 2, "c"}))
    end)

    it("table and table", function()
        assert.are.same(
            {a = true, b = true},
            Dict.update({a = true}, {a = false, b = true})
        )
    end)

    it("simple table", function()
        assert.are.same(
            {a = 1, b = 2, c = -2},
            Dict.update({a = 1, b = 2}, {a = 0, b = -1, c = -2})
        )
    end)

    it("nested table", function()
        assert.are.same(
            {a = 1, b = 2, c = -2, nested = {z = 100, x = 11}},
            Dict.update(
                {a = 1, b = 2, nested = {z = 100}},
                {a = 0, b = -1, c = -2, nested = {z = 10, x = 11}}
            )
        )
    end)

    it("double nested table", function()
        assert.are.same(
            {a = 1, b = { b1 = {c = 100}, b2 = {c = 20}, b3 = {c = 22}}},
            Dict.update(
                {a = 1, b = { b1 = {c = 100}, b2 = {c = 20}}},
                {a = 0, b = { b1 = {c = 10}, b2 = {c = 21}, b3 = {c = 22}}}
            )
        )
    end)
end)

describe("from", function()
    it("works", function()
        local a = {x = 1, y = 2}
        local b = {m = 3, n = 4}
        local c = Dict.from(a, b)

        assert.are.same({x = 1, y = 2}, a)
        assert.are.same({m = 3, n = 4}, b)
        assert.are.same({x = 1, y = 2, m = 3, n = 4}, c)
    end)
end)

describe("foreachk", function()
    it("works", function()
        local d = Dict({a = 1, b = 2})
        local l = List()

        d:foreachk(function(k) l:append(k) end)

        assert.are.same({'a', 'b'}, l)
    end)
end)

describe("foreachv", function()
    it("works", function()
        local d = Dict({a = 1, b = 2})
        local l = List()

        d:foreachv(function(v) l:append(v) end)

        assert.are.same({1, 2}, l)
    end)
end)

describe("foreachv", function()
    it("works", function()
        local d = Dict({a = 1, b = 2})
        local d2 = Dict({x = 3, y = 4})

        d:foreach(function(k, v) d2[k] = v end)

        assert.are.same({a = 1, b = 2, x = 3, y = 4}, d2)
    end)
end)

describe("transformk", function()
    it("works", function()
        local d = Dict({["1"] = "a", ["2"] = "b"})

        d:transformk(function(k) return tostring(tonumber(k) * -1) end)

        assert.are.same({["-1"] = "a", ["-2"] = "b"}, d)
    end)
end)

describe("transformv", function()
    it("works", function()
        local d = Dict({a = 1, b = 2})

        d:transformv(function(v) return v * -1 end)

        assert.are.same({a = -1, b = -2}, d)
    end)
end)

describe("filterv", function()
    it("works", function()
        local d = Dict({a = 1, b = 2, c = 3})

        d:filterv(function(v) return v ~= 2 end)

        assert.are.same({a = 1, c = 3}, d)
    end)
end)
