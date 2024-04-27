local htl = require("htl")
local mirrors = require("htl.db.mirrors")
local TaxonomyParser = require("htl.Taxonomy.Parser")

local M = require("htc.remove")

local kind = mirrors.conf:keys()[1]

local d1 = htl.test_dir / "dir-1"
local d2 = d1 / "dir-2"

local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"

local p1 = {title = "test", path = d1}

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
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
    
    it("cleans reference", function()
        f1:write("is a: x")

        DB.urls:insert({path = f1})
        local u1 = DB.urls:where({path = f1})
        local l1 = DB.urls:get_label(u1)

        f2:write(List({
            "is a: y",
            string.format("test_connection: %s", tostring(DB.urls:get_reference(u1))),
            "",
            "b",
        }))
        
        DB.urls:insert({path = f2})

        local u2 = DB.urls:where({path = f2})
        
        TaxonomyParser:record(u1)
        TaxonomyParser:record(u2)
        
        assert(DB.Relations:where({
            subject_url = u1.id,
            relation = "instance",
            object_label = "x",
        }))
        
        local u2_instance_r = {
            subject_url = u2.id,
            relation = "instance",
            object_label = "y",
        }
        
        assert(DB.Relations:where(u2_instance_r))
        assert(DB.Relations:where({
            subject_url = u2.id,
            relation = "connection",
            object_url = u1.id,
            type = "test_connection",
        }))
        
        M:remove_file(u1.path)
        
        assert.is_nil(DB.Relations:where({subject_url = u1.id}))
        assert(DB.Relations:where(u2_instance_r))
        assert(DB.Relations:where({
            subject_url = u2.id,
            relation = "connection",
            object_label = l1,
            type = "test_connection",
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
