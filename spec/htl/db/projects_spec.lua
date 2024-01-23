local Path = require("hl.Path")

local db = require("htl.db")
local projects = require("htl.db.projects")

local d1 = Path.tempdir:join("dir-1")
local f1 = d1:join("file-1.md")
local d2 = Path.tempdir:join("dir-2")
local f2 = d2:join("file-2.md")
local d3 = Path.tempdir:join("dir-3")
local f3 = d3:join("file-3.md")

before_each(function()
    d1:rmdir()
    d2:rmdir()
    d3:rmdir()
    db.before_test()
end)

after_each(function()
    db.after_test()
end)

describe("insert", function()
    it("works", function()
        local row = {title = "test", path = d1, created = "19930120"}
        projects:insert(row)
        assert.are.same(row, projects:where({title = "test"}))
    end)

    it("defaults date", function()
        local row = {title = "test", path = d1}
        projects:insert(row)
        row.created = os.date("%Y%m%d")
        assert.are.same(row, projects:where({title = "test"}))
    end)
end)

describe("get_path", function()
    local p1 = {title = "test1", path = d1}
    local p2 = {title = "test2", path = d2}

    it("match", function()
        projects:insert(p1)
        projects:insert(p2)
        
        assert.are.same(d1, projects:get_path(f1))
        assert.are.same(d2, projects:get_path(f2))
    end)
    
    it("no match", function()
        projects:insert(p1)
        
        assert.is_nil(projects:get_path(f2))
    end)
end)

