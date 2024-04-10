local Path = require("hl.Path")
local Config = require("htl.Config")
local Date = require("pl.Date")

local db = require("htl.db")
local projects = require("htl.db.projects")
local Urls = require("htl.db.urls")
local Link = require("htl.text.Link")

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
        Urls:insert({path = f1})
        assert.not_nil(Urls:where({path = tostring(f1)}))
    end)

    it("works with path", function()
        Urls:insert({path = f1})
        assert.not_nil(Urls:where({path = f1}))
    end)
end)

describe("insert", function()
    it("works", function()
        Urls:insert({project = p1.title, path = f1})
        local row = Urls:where({path = f1})

        assert.are.same(f1, row.path)
        assert.are.same(p1.title, row.project)
        assert.is_not.Nil(row.id)
    end)

    it("finds project", function()
        Urls:insert({path = f1})
        local result = Urls:where({path = f1})
        assert.are.same(p1.title, result.project)
    end)

    it("sets resource type", function()
        Urls:insert({path = f1})
        assert.not_nil(Urls:where({path = f1, resource_type = "file"}))
        Urls:insert({path = f2, label = "f2"})
        assert.not_nil(Urls:where({path = f2, resource_type = "link"}))
    end)

    it("doesn't overwrite file", function()
        Urls:insert({path = f1})
        
        local q = {where = {path = f1, resource_type = "file"}}
        assert.are.same(1, #Urls:get(q))
        Urls:insert({path = f1})
        assert.are.same(1, #Urls:get(q))
    end)
end)

describe("move", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        Urls:insert(a)
        Urls:insert(b)
        Urls:insert(c)

        Urls:move(f1, f3)

        assert.is_nil(Urls:where(a))
        assert.is_nil(Urls:where(b))
        assert.is_not.Nil(Urls:where(c))

        a.path = f3
        b.path = f3

        assert.are.same({"a", "b"}, Urls:get({where = {path = f3}}):col('label'):sorted())
    end)

    it("deletes if moving into a non-project dir", function()
        local pre = {path = f1, label = "a"}
        local post = {path = f5, label = "a"}

        Urls:insert(pre)
        assert.is_not.Nil(Urls:where(pre))

        Urls:move(f1, f5)

        assert.is_nil(Urls:where(pre))
        assert.is_nil(Urls:where(post))
    end)
end)

describe("remove", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        Urls:insert(a)
        Urls:insert(b)
        Urls:insert(c)

        Urls:remove({path = f1})

        assert.is_nil(Urls:where(a))
        assert.is_nil(Urls:where(b))
        assert.is_not.Nil(Urls:where(c))
    end)
end)

describe("get", function()
    it("works", function()
        Urls:insert({path = f1, label = "a"})
        Urls:insert({path = f2})

        assert.are.same(
            {"a"},
            Urls:get():transform(function(u)
                return u.label
            end):sorted()
        )
    end)
end)

describe("clean", function()
    it("non-existent file", function()
        f1:touch()
        local row = {path = f1}
        Urls:insert(row)
        assert.is_not.Nil(Urls:where(row))
        f1:unlink()
        Urls:clean()
        assert.is_nil(Urls:where(row))
    end)

    it("deleted project", function()
        local row = {path = f1}
        Urls:insert(row)
        assert.is_not.Nil(Urls:where(row))
        projects:remove({title = p1.title})
        assert.is_nil(Urls:where(row))
    end)

    it("unanchored file", function()
        Urls:insert({path = f1})
        local u1 = Urls:where({path = f1}).id
        Urls:update({
            where = {id = u1},
            set = {path = tostring(Urls.unanchored_path)},
        })

        local row = {path = Urls.unanchored_path}
        assert.is_not.Nil(Urls:where(row))
        Urls:clean()
        assert.is_nil(Urls:where(row))
    end)
end)

describe("new_link", function()
    it("picks the newest link", function()
        Urls:insert({path = f1, resource_type = "link"})
        local link_id = Urls:new_link(f1)
        
        assert.are.same(
            link_id,
            Urls:get():sort(function(a, b)
                return a.id > b.id
            end)[1]
        )
    end)
end)

describe("update_link_urls", function()
    it("updates a label", function()
        local id = Urls:new_link(f1).id
        Urls:update({
            where = {id = id},
            set = {label = "old"},
        })

        Urls:update_link_urls(f1, List({
            string.format("[new](:%d:)", id),
        }))

        assert.are.same("new", Urls:where({id = id}).label)
    end)

    it("updates a path", function()
        local id = Urls:new_link(f1).id
        Urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        Urls:update_link_urls(f2, List({
            string.format("[a](:%d:)", id),
        }))

        assert.are.same(f2, Urls:where({id = id}).path)
    end)

    it("moves a link", function()
        local id = Urls:new_link(f1).id
        Urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        Urls:update_link_urls(f2, List({
            string.format("[a](:%d:)", id),
        }))

        assert.are.same(f2, Urls:where({id = id}).path)
    end)

    it("unanchors a link", function()
        local id = Urls:new_link(f1).id
        Urls:update({
            where = {id = id},
            set = {label = "a"},
        })

        Urls:update_link_urls(f1, List())
        assert.are.same(Urls.unanchored_path, Urls:where({id = id}).path)
    end)
end)

describe("get_reference", function()
    it("label", function()
        assert.are.same(
            "[a](1)",
            tostring(Urls:get_reference({label = "a", id = 1}))
        )
    end)

    it("no label, non-dir file", function()
        assert.are.same(
            "[c](1)",
            tostring(Urls:get_reference({path = Path("a/b/c.md"), id = 1}))
        )
    end)

    it("no label, dir file", function()
        assert.are.same(
            "[b](1)",
            tostring(Urls:get_reference({path = Path("a/b/@.md"), id = 1}))
        )
    end)

    it("language file", function()
        assert.are.same(
            "[-suffix](1)",
            tostring(Urls:get_reference({path = Conf.paths.language_dir / "_suffix.md", id = 1}))
        )
    end)
end)

describe("set_date", function()
    it("works", function()
        Urls:insert({path = f1})
        local before = Urls:where({id = u1}).created
        local after = 19930120
        Urls:set_date(f1, after)
        assert.are.same(after, Urls:where({id = u1}).created)
    end)
end)
