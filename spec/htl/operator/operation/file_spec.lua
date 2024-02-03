local List = require("hl.List")

local stub = require('luassert.stub')
local db = require("htl.db")

local Path = require('hl.Path')

local projects = require("htl.db.projects")
local urls = require("htl.db.urls")

local Header = require("htl.text.header")

local Operator = require("htl.operator")
local Operation = require("htl.operator.operation")
local FileOperation = require("htl.operator.operation.file")

local test_dir = Path.join(tostring(Path.tempdir), "test-dir")

before_each(function()
    Path.rmdir(test_dir, true)
    
    db.before_test()
    db.get()

    stub(projects, 'get_path')
    projects.get_path.returns(test_dir)

    stub(urls, 'move')
end)

after_each(function()
    Path.rmdir(test_dir, true)
    projects.get_path:revert()
    urls.move:revert()
    db.after_test()
end)

describe("end to end", function()
    it("rename", function()
        local a_path = Path.join(test_dir, "a.md")
        local b_path = Path.join(test_dir, "b.md")
        local c_path = Path.join(test_dir, "c.md")

        local a_content = {"this is", "file a"}
        Path.write(a_path, a_content)

        local b_content_old = {"text", "[ref to a](a.md)", "more text"}
        Path.write(b_path, b_content_old)

        local b_content_new = {"text", "[ref to a](c.md)", "more text"}

        Operator.move({source = a_path, target = c_path})

        assert.falsy(Path.exists(a_path))

        assert.are.same(a_content, Path.readlines(c_path))
        assert.are.same(b_content_new, Path.readlines(b_path))
    end)
end)
