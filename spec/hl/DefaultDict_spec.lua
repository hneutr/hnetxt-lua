local List = require("hl.List")
local Set = require("hl.Set")
local Dict = require("hl.Dict")

local M = require("hl.DefaultDict")

describe("init", function()
    it("works", function()
        local list_d = M(List)
        
        assert.are.same({}, list_d.a)
        list_d.b:append(1)
        assert.are.same({1}, list_d.b)
        
        local set_d = M(Set)
        set_d.b:add(1)
        assert.are.same({1}, set_d.b:vals())
    end)
    
    it("doesn't overwrite", function()
        local d = M(List)
        d.a:append(1)
        assert.are.same({1}, d.a)
        d.a:append(2)
        assert.are.same({1, 2}, d.a)
        
        assert.are.same({"a"}, d:keys())
        
        local dict = Dict()
        assert.is_nil(dict.a)
    end)
    
    it("multiple don't interact", function()
        local d1 = M(List)
        local d2 = M(List)
        
        d1.a:append(1)
        assert.are.same({1}, d1.a)
        assert.are.same({}, d2.a)
        
        d2.a:append(2)
        assert.are.same({1}, d1.a)
        assert.are.same({2}, d2.a)
    end)
end)
