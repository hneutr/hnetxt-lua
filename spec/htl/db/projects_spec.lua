local d1 = htl.test_dir / "dir-1"
local d2 = htl.test_dir / "dir-2"
local d3 = htl.test_dir / "dir-3"
local d4 = d1 / "dir-4"

local f1 = d1 / "file-1.md"
local f2 = d2 / "file-2.md"
local f3 = d3 / "file-3.md"
local f4 = d4 / "file-4.md"

local M

before_each(function()
    htl.before_test()
    M = DB.projects
end)

after_each(function()
    htl.after_test()
end)

describe("insert", function()
    it("works", function()
        local row = {title = "test", path = d1, created = "19930120"}
        M:insert(row)
        assert.are.same(row, M:where({title = "test"}))
    end)

    it("defaults date", function()
        local row = {title = "test", path = d1}
        M:insert(row)
        row.created = os.date("%Y%m%d")
        assert.are.same(row, M:where({title = "test"}))
    end)
end)

describe("get_by_path", function()
    it("gets right project when nested", function()
        local p1 = {title = "p1", path = d1}
        local p4 = {title = "p4", path = d4}
        
        M:insert(p4)
        M:insert(p1)
        
        assert.are.same(M:where(p4), M.get_by_path(f4))
        M:remove()

        M:insert(p1)
        M:insert(p4)
        
        assert.are.same(M:where(p4), M.get_by_path(f4))
    end)
end)
