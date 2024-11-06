local M = require("hl.utils")

describe("randint", function()
    local fn = M.randint
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
    local fn = M.n_between

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
end)
