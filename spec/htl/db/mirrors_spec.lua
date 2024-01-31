local stub = require("luassert.stub")
local Path = require("hl.Path")

local Config = require("htl.config")

local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")
local mirrors

local d1 = Path.tempdir:join("dir-1")
local d2 = Path.tempdir:join("dir-2")

local f1 = d1:join("file-1.md")
local f2 = d2:join("file-2.md")

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930121"}

local test_config = Dict({
    a = {dir_prefix = ".x"},
    b = {dir_prefix = ".x"},
    c = {dir_prefix = ".y"},
})

before_each(function()
    d1:rmdir()
    d2:rmdir()

    stub(Config, 'get')
    Config.get.returns(test_config)

    mirrors = require("htl.db.mirrors")

    db.before_test()
    projects:insert(p1)
    projects:insert(p2)

    urls:insert({path = f1})
    urls:insert({path = f2})
end)

after_each(function()
    db.after_test()
    Config.get:revert()
end)

describe("set_project_config", function()
    it("has project", function()
        assert.are.same({}, mirrors.configs.projects)

        List({f1, f2}):foreach(function(f)
            local p = f:parent()
            assert.are.same(
                {
                    a = p:join('.x', 'a'),
                    b = p:join('.x', 'b'),
                    c = p:join('.y', 'c'),
                },
                mirrors:get_project_config(f).mirrors
            )
        end)
    end)

    it("no project", function()
        projects:remove({title = p1.title})
        assert.are.same({}, mirrors:get_project_config(f1))
    end)
end)

describe("get_mirror_kind", function()
    it("+", function()
        local conf = mirrors:get_project_config(d1)
        local f = conf.mirrors.a:join(f1:name())
        assert.are.same("a", mirrors:get_mirror_kind(f))
    end)

    it("-", function()
        assert.is_nil(mirrors:get_mirror_kind(f1))
    end)
end)

describe("is_mirror", function()
    it("+", function()
        local conf = mirrors:get_project_config(d1)
        local f = conf.mirrors.a:join(f1:name())
        assert(mirrors:is_mirror(f))
    end)

    it("-", function()
        assert.is_false(mirrors:is_mirror(f1))
    end)
end)

describe("is_source", function()
    it("+", function()
        assert.is_true(mirrors:is_source(f1))
    end)

    it("-", function()
        local conf = mirrors:get_project_config(d1)
        local f = conf.mirrors.a:join("1.md")
        assert.is_false(mirrors:is_source(f))
    end)
end)

describe("get_source_path", function()
    it("source", function()
        assert.are.same(f1, mirrors:get_source_path(f1))
    end)

    it("mirror", function()
        local conf = mirrors:get_project_config(d1)
        local f = conf.mirrors.a:join("1.md")
        assert.are.same(f1, mirrors:get_source_path(f))
    end)
end)

describe("get_mirror_path", function()
    local conf, f_a, f_b
    
    before_each(function()
        conf = mirrors:get_project_config(d1)
        f_a = conf.mirrors.a:join("1.md")
        f_b = conf.mirrors.b:join("1.md")
    end)

    it("same kind", function()
        assert.are.same(f_a, mirrors:get_mirror_path(f_a, "a"))
    end)

    it("source", function()
        assert.are.same(f_a, mirrors:get_mirror_path(f1, "a"))
    end)

    it("different kind", function()
        assert.are.same(f_a, mirrors:get_mirror_path(f_b, "a"))
    end)
end)

describe("get_mirror_paths", function()
    it("works", function()
        mirrors:insert_kind(f1, "a")
        mirrors:insert_kind(f1, "b")
        
        local conf = mirrors:get_project_config(d1)
        assert.are.same(
            {
                conf.mirrors.a:join("1.md"),
                conf.mirrors.b:join("1.md")
            },
            mirrors:get_mirror_paths(f1):sort(function(a, b)
                return tostring(a) < tostring(b)
            end)
        )
    end)
end)

describe("remove", function()
    it("works", function()
        urls:insert({path = f1})
        mirrors:insert_kind(f1, "a")
        assert.are.same(1, #mirrors:get_mirror_paths(f1))
        urls:remove({path = f1})
        assert.are.same(0, #mirrors:get_mirror_paths(f1))
    end)
end)
