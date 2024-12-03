local htl = require("htl")
local M = require("htl.Mirrors")
local Config = require("htl.Config")

local confs = {
    constants = Conf.mirror,
    test = Config.Mirrors.get_object({
        a = {},
        b = {},
        c = {},
    })
}

local d1 = htl.test_dir / "dir-1"
local d2 = htl.test_dir / "dir-2"

local f1 = d1 / "file-1.md"
local f2 = d2 / "file-2.md"

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930121"}

before_each(function()
    htl.before_test()

    f1:touch()
    f2:touch()

    DB.projects:insert(p1)
    DB.projects:insert(p2)

    DB.urls:insert({path = f1})
    DB.urls:insert({path = f2})

    Conf.mirror = confs.test
end)

after_each(function()
    htl.after_test()
    Conf.mirror = confs.constants
end)

describe("is_mirror", function()
    it("+", function()
        local f = Conf.mirror.a.path / f1:name()
        assert(M:is_mirror(f))
    end)

    it("-", function()
        assert.is_false(M:is_mirror(f1))
    end)
end)

describe("get_source", function()
    it("source", function()
        DB.urls:insert({path = f1})
        assert.are.same(DB.urls:where({path = f1}), M:get_source(f1))
    end)

    it("mirror", function()
        DB.urls:insert({path = f1})
        assert.are.same(
            DB.urls:where({path = f1}),
            M:get_source(Conf.mirror.a.path / "1.md")
        )
    end)
end)

describe("get_path", function()
    local f_a, f_b

    before_each(function()
        DB.urls:insert({path = f1})
        f_a = Conf.mirror.a.path / "1.md"
        f_b = Conf.mirror.b.path / "1.md"
    end)

    it("same kind", function()
        assert.are.same(f_a, M:get_path(f_a, "a"))
    end)

    it("source", function()
        assert.are.same(f_a, M:get_path(f1, "a"))
    end)

    it("different kind", function()
        assert.are.same(f_a, M:get_path(f_b, "a"))
    end)
end)

describe("get_kind", function()
    it("+", function()
        assert.are.same("a", M:get_kind(Conf.mirror.a.path / "file-1.md"))
        assert.are.same("b", M:get_kind(Conf.mirror.b.path / "file-1.md"))
    end)

    it("-", function()
        assert.is_nil(M:get_kind(Path("/a.md")))
    end)
end)
