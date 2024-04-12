local HTL = require("htl")

local mirrors = require("htl.db.mirrors")

local M = require("htc.remove")

local kind = mirrors.conf:keys()[1]

local d1 = HTL.test_dir / "dir-1"
local d2 = d1 / "dir-2"
local f1 = d1 / "file-1.md"

local p1 = {title = "test", path = d1}

before_each(function()
    HTL.before_test()
    DB.projects:insert(p1)
end)

after_each(function()
    HTL.after_test()
end)

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
        local m1 = mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        M:remove_file(f1)

        assert.is_falsy(m1:exists())
    end)

    it("mirror", function()
        f1:touch()
        DB.urls:insert({path = f1})
        local m1 = mirrors:get_path(f1, kind)

        local q = {path = m1}

        m1:touch()
        assert(m1:exists())

        M:remove_file(m1)
        assert.is_falsy(m1:exists())
        assert(f1:exists())
    end)
end)
