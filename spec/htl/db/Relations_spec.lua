local stub = require("luassert.stub")
local htl = require("htl")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local u1
local u2

local M

before_each(function()
    htl.before_test()
    M = DB.Relations
    DB.projects:insert(p1)
    DB.urls:insert({path = f1})
    DB.urls:insert({path = f2})
    
    DB.projects:insert({title = "global", path = Conf.paths.global_taxonomy_file:parent()})
    
    u1 = DB.urls:where({path = f1}).id
    u2 = DB.urls:where({path = f2}).id
end)

after_each(htl.after_test)

describe("set_url_label", function()
    before_each(function()
        stub(DB.urls, "set_label")
    end)

    after_each(function()
        DB.urls.set_label:revert()
    end)

    it("right relation", function()
        M:set_url_label({
            relation = "label",
            key = "xyz",
            source = u1,
        })

        assert.stub(DB.urls.set_label).was.called()
    end)
    
    it("wrong relation", function()
        M:set_url_label({
            relation = "connection",
            type = "etc",
            source = u1,
        })
        assert.stub(DB.urls.set_label).was_not.called()
    end)
end)

describe("insert", function()
    it("works", function()
        M:insert({subject = "a", object = u2, relation = "abc"}, u1)
        assert.not_nil(M:where({relation = "abc", source = u1}))
    end)
    
    it("works without subject", function()
        M:insert({object = u2, relation = "abc"}, u1)
        assert.not_nil(M:where({relation = "abc", source = u1}))
    end)
end)

describe("get_url_id", function()
    before_each(function()
        DB.projects:insert({title = "abc", path = Conf.paths.global_taxonomy_file:parent()})
    end)

    it("url", function()
        assert.are.same(1, M.get_url_id(1))
    end)
    
    it("doesn't exist", function()
        DB.urls:drop()
        assert.are.same(1, M.get_url_id("abc"))
    end)

    it("exists", function()
        DB.urls:drop()
        assert.are.same(1, M.get_url_id("abc"))
        assert.are.same(1, M.get_url_id("abc"))
    end)
end)
