local htl = require("htl")

local d1 = htl.test_dir / "dir-1"

local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"

local p1 = {title = "test", path = d1, created = "19930120"}
local u1
local u2

local M

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)

    f1:touch()
    f2:touch()
    
    DB.urls:insert({path = f1})
    DB.urls:insert({path = f2})
    
    u1 = DB.urls:where({path = f1}).id
    u2 = DB.urls:where({path = f2}).id
    
    M = DB.Elements
end)

after_each(htl.after_test)

describe("insert", function()
    it("string", function()
        M:insert("a")
        assert.not_nil(M:where({label = "a"}))
    end)
    
    it("url", function()
        local q = {source = u2}
        M:insert(u2)
        assert.not_nil(M:where({url = u2}))
    end)
    
    it("doesn't overwrite", function()
        local q = {label = "a", source = u2}
        assert.are.same(1, M:insert("a"))
        assert.are.same(1, M:insert("a"))
        assert.are.same(1, #M:get({where = {label = "a"}}))
    end)
end)
