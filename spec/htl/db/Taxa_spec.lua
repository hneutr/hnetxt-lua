local Taxa = require("htl.db.Taxa")

local Config = require("htl.Config")
local db = require("htl.db")
local projects = require("htl.db.projects")
local Urls = require("htl.db.urls")

local d1 = Config.test_root / "dir-1"
local f1 = d1 / "file-1.md"

local p1 = {title = "test", path = d1, created = "19930120"}

before_each(function()
    Config.before_test()
    db.setup()

    projects:insert(p1)
end)

after_each(function()
    Config.after_test()
end)

describe("find", function()
    it("url", function()
        f1:touch()
        Urls:insert({path = f1})
        local u = Urls:where({path = f1}).id
        assert.are.same({id = 1, url = u}, Taxa:find(u))
        assert.are.same({id = 1, url = u}, Taxa:find(u))
    end)
    
    it("key", function()
        assert.are.same({id = 1, key = "a"}, Taxa:find("a"))
        assert.are.same({id = 1, key = "a"}, Taxa:find("a"))
    end)

    it("key with project", function()
        Taxa:insert({key = "a"})
        assert.are.same({id = 1, key = "a"}, Taxa:find("a"))
        assert.are.same({id = 2, key = "a", project = "test"}, Taxa:find("a", "test"))
    end)
end)
