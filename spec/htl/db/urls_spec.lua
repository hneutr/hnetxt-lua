local Path = require("hl.Path")

local db = require("htl.db")
local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local d1 = Path.tempdir:join("dir-1")
local d2 = Path.tempdir:join("dir-2")
local d3 = Path.tempdir:join("dir-3")

local f1 = d1:join("file-1.md")
local f2 = d1:join("file-2.md")
local f3 = d1:join("file-3.md")
local f4 = d2:join("file-4.md")
local f5 = d3:join("file-5.md")

local p1 = {title = "test", path = d1, created = "19930120"}
local p2 = {title = "test2", path = d2, created = "19930121"}

before_each(function()
    d1:rmdir()
    db.before_test()
    projects:insert(p1)
    projects:insert(p2)
end)

after_each(function()
    db.after_test()
end)

describe("insert", function()
    it("works", function()
        urls:insert({project = p1.title, path = f1})
        local row = urls:where({path = f1})

        assert.are.same(f1, row.path)
        assert.are.same(p1.title, row.project)
        assert.is_not.Nil(row.id)
    end)

    it("finds project", function()
        urls:insert({path = f1})
        local result = urls:where({path = f1})
        assert.are.same(p1.title, result.project)
    end)

    it("sets defauls", function()
        urls:insert({path = f5})
        local result = urls:where({path = f5})
        assert.is_nil(result.project)
    end)
end)

describe("move", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        urls:insert(a)
        urls:insert(b)
        urls:insert(c)

        urls:move(f1, f3)

        assert.is_nil(urls:where(a))
        assert.is_nil(urls:where(b))
        assert.is_not.Nil(urls:where(c))

        a.path = f3
        b.path = f3

        assert.is_not.Nil(urls:where(a))
        assert.is_not.Nil(urls:where(b))
    end)
end)

describe("remove", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        urls:insert(a)
        urls:insert(b)
        urls:insert(c)

        urls:remove({path = f1})

        assert.is_nil(urls:where(a))
        assert.is_nil(urls:where(b))
        assert.is_not.Nil(urls:where(c))
    end)
end)

describe("get", function()
    it("works", function()
        urls:insert({path = f1, label = "a"})
        urls:insert({path = f2})

        assert.are.same(
            {"a", "file 2"},
            urls:get():transform(function(u)
                return u.label
            end):sorted()
        )
    end)
end)

describe("add_if_missing", function()
    it("+", function()
        urls:add_if_missing(f1)
        assert(urls:where({path = f1}))
    end)

    it("doesn't overwrite", function()
        local row = {path = f1, label = "a"}
        urls:insert(row)
        urls:add_if_missing(row.path)
        assert.is_not.Nil(urls:where(row))
    end)
end)

describe("clean", function()
    it("non-existent file", function()
        f1:touch()
        local row = {path = f1}
        urls:insert(row)
        assert.is_not.Nil(urls:where(row))
        f1:unlink()
        urls:clean()
        assert.is_nil(urls:where(row))
    end)

    it("deleted project", function()
        local row = {path = f1}
        urls:insert(row)
        assert.is_not.Nil(urls:where(row))
        projects:remove({title = p1.title})
        assert.is_nil(urls:where(row))
    end)
end)