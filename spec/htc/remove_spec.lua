local Path = require('hl.Path')

local remove = require("htc.remove")

local db = require("htl.db")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")
local projects = require("htl.db.projects")

local kind = mirrors.conf:keys()[1]

local d1 = Path.tempdir:join("dir-1")
local d2 = d1:join("dir-2")

local f1 = d1:join("file-1.md")

local p1 = {title = "test", path = d1}

before_each(function()
    db.before_test()

    d1:rmdir(true)

    projects:insert(p1)
end)

after_each(function()
    db.after_test()

    d1:rmdir(true)
end)

describe("remove_file", function()
    it("source", function()
        f1:touch()
        assert(f1:exists())
        remove:remove_file(f1)
        assert.is_false(f1:exists())
    end)

    it("source w/ url", function()
        local r = {path = f1}

        f1:touch()
        urls:insert(r)
        assert(urls:where(r))

        remove:remove_file(f1)

        assert.is_falsy(urls:where(r))
    end)

    it("source w/ mirrors", function()
        f1:touch()
        urls:insert({path = f1})
        local m1 = mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        remove:remove_file(f1)

        assert.is_falsy(m1:exists())
    end)

    it("mirror", function()
        f1:touch()
        urls:insert({path = f1})
        local m1 = mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        remove:remove_file(m1)
        assert.is_falsy(m1:exists())
        assert(f1:exists())
    end)
end)
