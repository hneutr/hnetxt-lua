local stub = require("luassert.stub")
local htl = require("htl")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local M

before_each(function()
    htl.before_test()
    M = DB.Relations
    DB.projects:insert(p1)
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
        M:set_url_label({subject_url = 1, relation = "connection", type = "label"})
        assert.stub(DB.urls.set_label).was.called()
    end)
    
    it("wrong relation", function()
        M:set_url_label({subject_url = 1, relation = "connection", type = "abc"})
        assert.stub(DB.urls.set_label).was_not.called()
    end)
end)
