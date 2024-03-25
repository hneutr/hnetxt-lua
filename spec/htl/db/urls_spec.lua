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
    d2:rmdir()
    db.before_test()
    projects:insert(p1)
    projects:insert(p2)
    f1:touch()
    f2:touch()
    f3:touch()
    f4:touch()
    f5:touch()
end)

after_each(function()
    db.after_test()
end)

describe("where", function()
    it("works with string", function()
        urls:insert({path = f1})
        assert.not_nil(urls:where({path = tostring(f1)}))
    end)

    it("works with path", function()
        urls:insert({path = f1})
        assert.not_nil(urls:where({path = f1}))
    end)
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

    it("sets defaults", function()
        urls:insert({path = f5})
        local result = urls:where({path = f5})
        assert.is_nil(result.project)
    end)

    it("sets resource type", function()
        urls:insert({path = f1})
        assert.not_nil(urls:where({path = f1, resource_type = "file"}))
        urls:insert({path = f2, label = "f2"})
        assert.not_nil(urls:where({path = f2, resource_type = "link"}))
    end)

    it("doesn't overwrite file", function()
        urls:insert({path = f1})
        
        local q = {where = {path = f1, resource_type = "file"}}
        assert.are.same(1, #urls:get(q))
        urls:insert({path = f1})
        assert.are.same(1, #urls:get(q))
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

        assert.are.same({"a", "b"}, urls:get({where = {path = f3}}):col('label'):sorted())
    end)

    it("deletes if moving into a non-project dir", function()
        local pre = {path = f1, label = "a"}
        local post = {path = f5, label = "a"}

        urls:insert(pre)
        assert.is_not.Nil(urls:where(pre))

        urls:move(f1, f5)

        assert.is_nil(urls:where(pre))
        assert.is_nil(urls:where(post))
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
            {"a"},
            urls:get():transform(function(u)
                return u.label
            end):sorted()
        )
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

    it("unanchored file", function()
        urls:insert({path = f1})
        local u1 = urls:where({path = f1}).id
        urls:update({
            where = {id = u1},
            set = {path = tostring(urls.unanchored_path)},
        })

        local row = {path = urls.unanchored_path}
        assert.is_not.Nil(urls:where(row))
        urls:clean()
        assert.is_nil(urls:where(row))
    end)
end)

describe("new_link", function()
    it("picks the newest link", function()
        urls:insert({path = f1, resource_type = "link"})
        local link_id = urls:new_link(f1)
        
        assert.are.same(
            link_id,
            urls:get():sort(function(a, b)
                return a.id > b.id
            end)[1]
        )
    end)
end)

describe("update_link_urls", function()
    it("updates a label", function()
        local id = urls:new_link(f1).id
        urls:update({
            where = {id = id},
            set = {label = "old"},
        })

        urls:update_link_urls(f1, List({
            string.format("[new](:%d:)", id),
        }))

        assert.are.same("new", urls:where({id = id}).label)
    end)

    it("updates a path", function()
        local id = urls:new_link(f1).id
        urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        urls:update_link_urls(f2, List({
            string.format("[a](:%d:)", id),
        }))

        assert.are.same(f2, urls:where({id = id}).path)
    end)

    it("moves a link", function()
        local id = urls:new_link(f1).id
        urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        urls:update_link_urls(f2, List({
            string.format("[a](:%d:)", id),
        }))

        assert.are.same(f2, urls:where({id = id}).path)
    end)

    it("unanchors a link", function()
        local id = urls:new_link(f1).id
        urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        urls:update_link_urls(f1, List())
        assert.are.same(urls.unanchored_path, urls:where({id = id}).path)
    end)
end)
