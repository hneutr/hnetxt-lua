local htl = require("htl")
local d1 = htl.test_dir / "dir-1"
local d2 = d1 / "dir-2"

local f1 = d1 / "file-1.md"
local f2 = d2 / "file-2.md"

local p1 = {title = "1", path = d1}
local p2 = {title = "2", path = d2}

local M

before_each(function()
    htl.before_test()
    M = DB.projects
end)

after_each(htl.after_test)

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
    
    it("updates urls of subfiles", function()
        M:insert(p1)
        local u1 = DB.urls:insert({path = f2})
        assert.are.same(p1.title, DB.urls:where({path = f2}).project)
        M:insert(p2)
        assert.are.same(p2.title, DB.urls:where({path = f2}).project)
    end)
end)

describe("get_by_path", function()
    it("gets right project when nested", function()
        M:insert(p2)
        M:insert(p1)
        
        assert.are.same(M:where(p2), M.get_by_path(f2))
    end)
end)

describe("remove", function()
    it("url in non-nested project gets deleted", function()
        M:insert(p1)
        DB.urls:insert({path = f1})
        
        M:remove(p1)
        assert.is_nil(DB.urls:where({path = f1}))
    end)

    it("url in nested project updates", function()
        M:insert(p1)
        M:insert(p2)

        DB.urls:insert({path = f2})

        assert.are.same(p2.title, DB.urls:where({path = f2}).project)
        M:remove(p2)
        assert.are.same(p1.title, DB.urls:where({path = f2}).project)
    end)
end)

describe("move", function()
    it("dir is a project", function()
        local d1 = htl.test_dir / "d1"
        local d2 = d1 / "d2"
        local d3 = d1 / "d3"

        M:drop()
        M:insert({title = "1", path = d1})
        M:insert({title = "2", path = d2})
        
        assert(M:where({path = d2}))
        M.move({source = d2, target = d3})

        assert.is_nil(M:where({path = d2}))
        assert(M:where({path = d3}))
    end)
    
    it("dir with multiple projects", function()
        local a = htl.test_dir / "a"
        local b = htl.test_dir / "b"
        local ac = a / "c"
        local bc = b / "c"

        M:drop()

        M:insert({title = "a", path = a})
        M:insert({title = "c", path = ac})
        
        assert(M:where({path = a}))
        assert(M:where({path = ac}))

        M.move({source = a, target = b})

        assert.is_nil(M:where({path = a}))
        assert.is_nil(M:where({path = ac}))

        assert(M:where({path = b}))
        assert(M:where({path = bc}))
    end)
end)
