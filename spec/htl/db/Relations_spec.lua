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
    f1:touch()
    f2:touch()
    M = DB.Relations
    DB.projects:insert(p1)
    DB.urls:insert({path = f1})
    DB.urls:insert({path = f2})
    
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
        M:set_url_label({relation = "connection", type = "label"}, {label = "a", source = 1})
        assert.stub(DB.urls.set_label).was.called()
    end)
    
    it("wrong relation", function()
        M:set_url_label({relation = "connection", type = "abc"}, {label = "a", source = 1})
        assert.stub(DB.urls.set_label).was_not.called()
    end)
end)

describe("insert", function()
    it("works", function()
        M:insert({subject = "a", object = u2, relation = "abc"}, u1)
        assert.not_nil(M:where({relation = "abc"}))
    end)
    
    it("works without subject", function()
        M:insert({object = u2, relation = "abc"}, u1)
        assert.not_nil(M:where({relation = "abc"}))
    end)

    it("doesn't insert if existing", function()
        assert.are.same(1, M:insert({subject = "a", object = u2, relation = "abc"}, u1))
        assert.are.same(1, M:insert({subject = "a", object = u2, relation = "abc"}, u1))
    end)
end)
