local htl = require("htl")
local Mirrors = require("htl.Mirrors")

local M = require("htc.remove")

local kind = Conf.mirror:keys()[1]

local d1 = htl.test_dir / "dir-1"
local d2 = d1 / "dir-2"

local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local f3 = d2 / "f1.md"

local p1 = {title = "test", path = d1}

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
    DB.projects:insert({title = "global", path = Conf.paths.global_taxonomy_file:parent()})
end)

after_each(htl.after_test)

describe("remove_file", function()
    it("source", function()
        f1:touch()
        assert(f1:exists())
        M:remove_file(f1)
        assert.is_false(f1:exists())
    end)

    it("source w/ url", function()
        local r = {path = f1}

        f1:touch()
        DB.urls:insert(r)
        assert(DB.urls:where(r))

        M:remove_file(f1)

        assert.is_falsy(DB.urls:where(r))
    end)

    it("source w/ mirrors", function()
        f1:touch()
        DB.urls:insert({path = f1})
        local m1 = Mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        M:remove_file(f1)

        assert.is_falsy(m1:exists())
    end)

    it("mirror", function()
        f1:touch()
        DB.urls:insert({path = f1})
        local m1 = Mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        M:remove_file(m1)
        assert.is_falsy(m1:exists())
        assert(f1:exists())
    end)
end)

describe("remove_dir", function()
    it("deletes projects", function()
        DB.projects:insert({title = "2", path = d2})
        
        f3:touch()
        M:remove_dir(d1, {directories = true, recursive = true})
        assert.is_nil(DB.projects:where({path = d1}))
        assert.is_nil(DB.projects:where({path = d2}))
    end)
end)
