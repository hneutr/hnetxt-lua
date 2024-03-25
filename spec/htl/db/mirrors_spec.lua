local stub = require("luassert.stub")
local Path = require("hl.Path")

local Config = require("htl.Config")
local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")
local mirrors = require("htl.db.mirrors")

local d1 = Path.tempdir:join("dir-1")
local d2 = Path.tempdir:join("dir-2")

local f1 = d1:join("file-1.md")
local f2 = d2:join("file-2.md")

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930121"}

local test_config = Dict({
    a = {},
    b = {},
    c = {},
})

before_each(function()
    d1:rmdir(true)
    d2:rmdir(true)

    db.before_test()

    f1:touch()
    f2:touch()

    projects:insert(p1)
    projects:insert(p2)

    urls:insert({path = f1})
    urls:insert({path = f2})

    mirrors:set_conf(test_config)
end)

after_each(function()
    db.after_test()
end)

describe("is_mirror", function()
    it("+", function()
        local f = mirrors.conf.a.path / f1:name()
        assert(mirrors:is_mirror(f))
    end)

    it("-", function()
        assert.is_false(mirrors:is_mirror(f1))
    end)
end)

describe("get_source", function()
    it("source", function()
        urls:insert({path = f1})
        assert.are.same(urls:where({path = f1}), mirrors:get_source(f1))
    end)

    it("mirror", function()
        urls:insert({path = f1})
        assert.are.same(
            urls:where({path = f1}),
            mirrors:get_source(mirrors.conf.a.path / "1.md")
        )
    end)
end)

describe("get_path", function()
    local f_a, f_b
    
    before_each(function()
        urls:insert({path = f1})
        f_a = mirrors.conf.a.path / "1.md"
        f_b = mirrors.conf.b.path / "1.md"
    end)

    it("same kind", function()
        assert.are.same(f_a, mirrors:get_path(f_a, "a"))
    end)

    it("source", function()
        assert.are.same(f_a, mirrors:get_path(f1, "a"))
    end)

    it("different kind", function()
        assert.are.same(f_a, mirrors:get_path(f_b, "a"))
    end)
end)

describe("get_kind", function()
    it("+", function()
        assert.are.same("a", mirrors:get_kind(mirrors.conf.a.path / "file-1.md"))
        assert.are.same("b", mirrors:get_kind(mirrors.conf.b.path / "file-1.md"))
    end)

    it("-", function()
        assert.is_nil(mirrors:get_kind(Path("/a.md")))
    end)
end)
