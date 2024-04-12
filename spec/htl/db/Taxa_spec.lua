local Config = require("htl.Config")
local db = require("htl.db")

local d1 = Config.test_root / "dir-1"
local d2 = d1 / "dir-2"
local f1 = d1 / "file-1.md"

local p1 = {title = "test1", path = d1}
local p2 = {title = "test2", path = d2}

local M

before_each(function()
    Config.before_test()
    db.setup()

    DB.projects:insert(p1)
    DB.projects:insert(p2)
    
    M = DB.Taxa
end)

after_each(function()
    Config.after_test()
end)

describe("where", function()
    describe("url", function()
        local u
        before_each(function()
            f1:touch()
            DB.urls:insert({path = f1})
            u = DB.urls:where({path = f1}).id
            M:insert({url = u})
        end)
        
        it("no project", function()
            assert.are.same({id = 1, url = u}, M:where({url = u}))
        end)

        it("project: +", function()
            assert.are.same({id = 1, url = u}, M:where({url = u, project = "test1"}))
        end)

        it("project: -", function()
            assert.is_nil(M:where({url = u, project = "test2"}))
        end)
    end)
    
    describe("key", function()
        local k1 = "key-1"
        local k2 = "key-2"

        it("no project", function()
            M:insert({key = k1, project = "test1"})
            M:insert({key = k2})
            M:insert({key = k1})
            assert.are.same({id = 3, key = k1}, M:where({key = k1}))
        end)

        it("project: +, project row", function()
            M:insert({key = k1})
            M:insert({key = k1, project = "test1"})
            assert.are.same({id = 2, key = k1, project = "test1"}, M:where({key = k1, project = "test1"}))
        end)


        it("project: +, no project row", function()
            M:insert({key = k1, project = "test2"})
            M:insert({key = k1})
            assert.are.same({id = 2, key = k1}, M:where({key = k1, project = "test1"}))
        end)

        it("project: -", function()
            M:insert({key = k1, project = "test2"})
            assert.is_nil(M:where({key = k1, project = "test1"}))
        end)
    end)
end)

describe("find", function()
    it("url", function()
        f1:touch()
        DB.urls:insert({path = f1})
        local u = DB.urls:where({path = f1}).id
        assert.are.same({id = 1, url = u}, M:find(u))
        assert.are.same({id = 1, url = u}, M:find(u))
    end)
    
    it("key", function()
        assert.are.same({id = 1, key = "a"}, M:find("a"))
        assert.are.same({id = 1, key = "a"}, M:find("a"))
    end)

    it("key with project", function()
        M:insert({key = "a"})
        assert.are.same({id = 1, key = "a"}, M:find("a", "test1"))
    end)
end)
