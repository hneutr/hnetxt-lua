local Path = require("hl.Path")

local Config = require("htl.Config")

local db = require("htl.db")
local Projects = require("htl.db.projects")

local d1 = Config.test_root / "dir-1"
local d2 = Config.test_root / "dir-2"
local d3 = Config.test_root / "dir-3"
local d4 = d1 / "dir-4"

local f1 = d1 / "file-1.md"
local f2 = d2 / "file-2.md"
local f3 = d3 / "file-3.md"
local f4 = d4 / "file-4.md"

before_each(function()
    db.before_test()
end)

after_each(function()
    db.after_test()
end)

describe("insert", function()
    it("works", function()
        local row = {title = "test", path = d1, created = "19930120"}
        Projects:insert(row)
        assert.are.same(row, Projects:where({title = "test"}))
    end)

    it("defaults date", function()
        local row = {title = "test", path = d1}
        Projects:insert(row)
        row.created = os.date("%Y%m%d")
        assert.are.same(row, Projects:where({title = "test"}))
    end)
end)

describe("get_by_path", function()
    it("gets right project when nested", function()
        local p1 = {title = "p1", path = d1}
        local p4 = {title = "p4", path = d4}
        
        Projects:insert(p4)
        Projects:insert(p1)
        
        assert.are.same(Projects:where(p4), Projects.get_by_path(f4))
        Projects:remove()

        Projects:insert(p1)
        Projects:insert(p4)
        
        assert.are.same(Projects:where(p4), Projects.get_by_path(f4))
    end)
end)
