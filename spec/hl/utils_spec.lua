local List = require("hl.List")
local Dict = require("hl.Dict")
local UnitTest = require("hl.UnitTest")

local M = require("hl.utils")

describe("randint", function()
    local fn = math.randint
    it("no args", function()
        assert.are.same(1, fn())
    end)

    it("set min", function()
        assert.are.same(2, fn({min = 2}))
    end)

    it("set max", function()
        assert.not_nil(fn({min = 1, max = 100}))
    end)

    it("seed", function()
        local args = {min = 1, max = 100, seed = 1234}
        assert.are.same(fn(args), fn(args))
    end)
end)

describe("parsekv", function()
    local fn = M.parsekv

    it("nil", function()
        assert.are.same({""}, {fn()})
    end)

    it("no val", function()
        assert.are.same({"key"}, {fn("key: ")})
    end)

    it("key and val", function()
        assert.are.same({"key", "val"}, {fn("key: val ")})
    end)

    it("alternate delimiter", function()
        assert.are.same({"key", "val"}, {fn("key@ val ", "@")})
    end)
end)

describe("between", function()
    local fn = math.between

    it("min <= x <= max", function()
        assert.are.same(1, fn(1, {min = 0, max = 2}))
    end)

    it("x == min, exclusive", function()
        assert.are.same(1, fn(0, {min = 0, max = 2, exclusive = true}))
    end)

    it("x == max, exclusive", function()
        assert.are.same(1, fn(2, {min = 0, max = 2, exclusive = true}))
    end)

    it("x < min", function()
        assert.are.same(1, fn(0, {min = 1, max = 2}))
    end)

    it("max < x", function()
        assert.are.same(1, fn(2, {min = 0, max = 1}))
    end)

    it("max < min", function()
        assert.are.same(2, fn(3, {min = 2, max = 0}))
    end)

    it("min > max", function()
        assert.are.same(2, fn(3, {min = 2, max = 0}))
    end)
end)

describe("typeify", function()
    local fn = M.typify
    it("list", function()
        assert.are.same(List, getmetatable(fn({1})))
    end)

    it("list with dict", function()
        local out = fn({1, {x = 1}})

        assert.are.same(List, getmetatable(out))
        assert.are.same(getmetatable(1), getmetatable(out[1]))
        assert.are.same(Dict, getmetatable(out[2]))
    end)

    it("dict", function()
        assert.are.same(Dict, getmetatable(fn({x = 1})))
    end)

    it("dict with list", function()
        local out = fn({x = 1, y = {1}})

        assert.are.same(Dict, getmetatable(out))
        assert.are.same(getmetatable(1), getmetatable(out.x))
        assert.are.same(List, getmetatable(out.y))
    end)
end)
