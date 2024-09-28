local htl = require("htl")
local Mirrors = require("htl.Mirrors")
local Date = require("pl.Date")
local TaxonomyParser = require("htl.Taxonomy.Parser")

local Link = require("htl.text.Link")

local d1 = htl.test_dir / "dir-1"
local d2 = htl.test_dir / "dir-2"
local d3 = htl.test_dir / "dir-3"

local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local f3 = d1 / "file-3.md"
local f4 = d2 / "file-4.md"
local f5 = d3 / "file-5.md"

local p1 = {title = "test", path = d1}
local p2 = {title = "test2", path = d2}

local M

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
    DB.projects:insert(p2)
    f1:touch()
    f2:touch()
    f3:touch()
    f4:touch()
    f5:touch()
    
    M = DB.urls
end)

after_each(htl.after_test)

describe("where", function()
    it("works with string", function()
        M:insert({path = f1})
        assert.not_nil(M:where({path = tostring(f1)}))
    end)

    it("works with path", function()
        M:insert({path = f1})
        assert.not_nil(M:where({path = f1}))
    end)
end)

describe("insert", function()
    it("works", function()
        M:insert({project = p1.title, path = f1})
        local row = M:where({path = f1})

        assert.are.same(f1, row.path)
        assert.are.same(p1.title, row.project)
        assert.is_not.Nil(row.id)
    end)

    it("finds project", function()
        M:insert({path = f1})
        local result = M:where({path = f1})
        assert.are.same(p1.title, result.project)
    end)

    it("no project", function()
        assert.is_nil(M:insert({path = f5}))
    end)

    it("sets resource type", function()
        M:insert({path = f1})
        assert.not_nil(M:where({path = f1, type = "file"}))
        M:insert({path = f2, label = "f2"})
        assert.not_nil(M:where({path = f2, type = "link"}))
    end)

    it("doesn't overwrite file", function()
        M:insert({path = f1})

        local q = {where = {path = f1, type = "file"}}
        assert.are.same(1, #M:get(q))
        M:insert({path = f1})
        assert.are.same(1, #M:get(q))
    end)

    it("sets date", function()
        M:insert({path = f1, created = 19930120})
        assert.are.same(19930120, M:where({path = f1}).created)
    end)
end)

describe("move", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        M:insert(a)
        M:insert(b)
        M:insert(c)

        M.move({source = f1, target = f3})

        assert.is_nil(M:where(a))
        assert.is_nil(M:where(b))
        assert.is_not.Nil(M:where(c))

        assert.are.same(
            {"a", "b"},
            M:get({where = {path = f3, type = "link"}}):col('label'):sorted()
        )
    end)

    it("deletes if moving into a non-project dir", function()
        local pre = {path = f1, label = "a"}
        local post = {path = f5, label = "a"}

        M:insert(pre)
        assert.is_not.Nil(M:where(pre))

        M.move({source = f1, target = f5})

        assert.is_nil(M:where(pre))
        assert.is_nil(M:where(post))
    end)

    it("source url exists and target should have url", function()
        local d1 = htl.test_dir / "1"
        local f1 = d1 / "f1.md"
        local f2 = d1 / "f2.md"

        DB.projects:drop()
        DB.projects:insert({title = "1", path = d1})
        local u1 = M:insert({path = f1})
        assert.is_not.Nil(M:where({path = f1}))

        M.move({source = f1, target = f2})
        assert.is_nil(M:where({path = f1}))
        assert.is_not.Nil(M:where({path = f2}))
    end)

    it("source url exists and target should not have url", function()
        local d_a = htl.test_dir / "a"
        local d_b = htl.test_dir / "b"
        local f_a1 = d_a / "1.md"
        local f_b1 = d_b / "1.md"

        DB.projects:drop()
        DB.projects:insert({title = "a", path = d_a})
        local u1 = M:insert({path = f_a1})
        assert.is_not.Nil(M:where({path = f_a1}))

        M.move({source = f_a1, target = f_b1})
        assert.is_nil(M:where({path = f_a1}))
        assert.is_nil(M:where({path = f_b1}))
    end)

    it("source has no url and target should have url", function()
        local d_a = htl.test_dir / "a"
        local d_b = htl.test_dir / "b"
        local f_a1 = d_a / "1.md"
        local f_b1 = d_b / "1.md"

        DB.projects:drop()
        DB.projects:insert({title = "a", path = d_a})

        M.move({source = f_b1, target = f_a1})
        assert.is_nil(M:where({path = f_b1}))
        assert.is_not.Nil(M:where({path = f_a1}))
    end)
end)

describe("should_track", function()
    it("+", function()
        assert(M.should_track(f1))
    end)

    it("-: suffix", function()
        assert.is_false(M.should_track(f1:with_suffix(".xyz")))
    end)

    it("-: suffix", function()
        DB.urls:insert({path = f1})
        local mirror = Mirrors:get_path(f1, Conf.mirror:keys()[1])
        assert.is_false(M.should_track(mirror))
    end)

    it("-: not project", function()
        assert.is_false(M.should_track(htl.test_dir / f1:name()))
    end)
end)

describe("remove", function()
    it("works", function()
        local a = {path = f1, label = "a"}
        local b = {path = f1, label = "b"}
        local c = {path = f2, label = "c"}

        M:insert(a)
        M:insert(b)
        M:insert(c)

        M:remove({path = f1})

        assert.is_nil(M:where(a))
        assert.is_nil(M:where(b))
        assert.is_not.Nil(M:where(c))
    end)

    -- removes references
    it("cleans reference", function()
        f1:write("is a: x")

        DB.urls:insert({path = f1})
        local u1 = DB.urls:where({path = f1})
        local l1 = u1.label

        f2:write(List({
            "is a: y",
            string.format("test_connection: %s", tostring(M:get_reference(u1))),
            "",
            "b",
        }))

        DB.urls:insert({path = f2})

        local u2 = DB.urls:where({path = f2})

        TaxonomyParser:record(u1)
        TaxonomyParser:record(u2)

        assert(DB.Relations:where({
            subject = u1.id,
            relation = "instance",
            object = DB.Relations.get_url_id("x"),
        }))

        local u2_instance_r = {
            subject = u2.id,
            relation = "instance",
            object = DB.Relations.get_url_id("y"),
        }

        assert(DB.Relations:where(u2_instance_r))

        assert(DB.Relations:where({
            subject = u2.id,
            relation = "connection",
            object = u1.id,
            key = "test_connection",
        }))

        M:remove({id = u1.id})
        assert.is_nil(DB.Relations:where({subject = u1.id}))

        assert(DB.Relations:where(u2_instance_r))

        assert(DB.Relations:where({
            subject = u2.id,
            relation = "connection",
            val = l1,
            key = "test_connection",
        }))

        assert.are.same(
            {
                "is a: y",
                string.format("test_connection: %s", l1),
                "",
                "b",
            },
            f2:readlines()
        )
    end)
end)

describe("remove_references_to_url", function()
    it("cleans reference", function()
        f1:write("is a: x")

        DB.urls:insert({path = f1})
        local u1 = DB.urls:where({path = f1})
        local l1 = u1.label

        f2:write(List({
            "is a: y",
            string.format("test_connection: %s", tostring(M:get_reference(u1))),
            "",
            "b",
        }))

        DB.urls:insert({path = f2})

        local u2 = DB.urls:where({path = f2})

        TaxonomyParser:record(u1)
        TaxonomyParser:record(u2)

        assert(DB.Relations:where({
            subject = u1.id,
            relation = "instance",
            object = DB.Relations.get_url_id("x"),
        }))

        local u2_instance_r = {
            subject = u2.id,
            relation = "instance",
            object = DB.Relations.get_url_id("y"),
        }

        assert(DB.Relations:where(u2_instance_r))

        assert(DB.Relations:where({
            subject = u2.id,
            relation = "connection",
            object = u1.id,
            key = "test_connection",
        }))

        M.remove_references_to_url(u1)

        assert(DB.Relations:where(u2_instance_r))

        assert(DB.Relations:where({
            subject = u2.id,
            relation = "connection",
            val = l1,
            key = "test_connection",
        }))

        assert.are.same(
            {
                "is a: y",
                string.format("test_connection: %s", l1),
                "",
                "b",
            },
            f2:readlines()
        )
    end)
end)

describe("get", function()
    it("works", function()
        M:insert({path = f1, label = "a"})
        M:insert({path = f2, label = "b"})

        assert.are.same(
            {"a", "b"},
            M:get():transform(function(u)
                return u.label
            end):sorted()
        )
    end)
end)

describe("get_label", function()
    it("label", function()
        assert.are.same("a", tostring(M:get_label({label = "a"})))
    end)

    it("no label, non-dir file", function()
        assert.are.same("c", M:get_label({path = Path("a/b/c.md")}))
    end)

    it("no label, dir file", function()
        assert.are.same("b", M:get_label({path = Path("a/b/@.md")}))
    end)

    it("language file", function()
        assert.are.same("-suffix", M:get_label({path = Conf.paths.language_dir / "_suffix.md"}))
    end)
end)

describe("set_project", function()
    it("works", function()
        DB.projects:drop()
        DB.urls:drop()

        local d1 = htl.test_dir / "d1"
        local d2 = d1 / "d2"

        local f1 = d2 / "f1.md"

        local p1 = {path = d1, title = "1"}
        local p2 = {path = d2, title = "2"}

        DB.projects:insert(p1)

        local u1 = DB.urls:insert({path = f1})

        assert.are.same("1", DB.urls:get_file(f1).project)

        DB.projects:insert(p2)
        DB.urls:update_project(f1)

        assert.are.same("2", DB.urls:get_file(f1).project)
    end)
end)

describe("set_label", function()
    local l1 = M:get_label({path = f1})

    it("str", function()
        local q = {path = f1}
        f1:touch()

        M:insert(q)
        local u = M:where(q)
        assert.are.same(l1, u.label)

        M:set_label(u.id, "a")

        assert.are.same("a", M:where(q).label)
    end)

    it("nil", function()
        f1:touch()
        local id = M:insert({path = f1, label = "a"})
        assert.are.same("a", M:where({id = id}).label)

        M:set_label(id)
        assert.are.same(l1, M:where({id = id}).label)
    end)
end)

describe("clean", function()
    it("deleted file", function()
        local r = {path = f1}
        M:insert(r)

        assert(M:where(r))

        f1:unlink()

        M:clean()

        assert.is_nil(M:where(r))
    end)

    it("unanchored file", function()
        local r = {id = M:insert({path = f1})}

        M:update({
            where = r,
            set = {path = tostring(M.unanchored_path)},
        })

        assert(M:where(r))
        M:clean()
        assert.is_nil(M:where(r))
    end)

    it("not relative to project", function()
        local r = {id = M:insert({path = f1})}

        M:update({
            where = r,
            set = {path = tostring(d2 / f1:name())},
        })

        assert(M:where(r))
        M:clean()
        assert.is_nil(M:where(r))
    end)

    it("+", function()
        local r = {id = M:insert({path = f1})}

        assert(M:where(r))
        M:clean()
        assert(M:where(r))
    end)
end)

