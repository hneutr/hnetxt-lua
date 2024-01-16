local List = require("hl.List")

local stub = require('luassert.stub')

local Path = require('hl.Path')

local Project = require("htl.project")
local Mirror = require("htl.project.mirror")
local Header = require("htl.text.header")
local Parser = require("htl.parse")

local Operator = require("htl.operator")
local Operation = require("htl.operator.operation")
local FileOperation = require("htl.operator.operation.file")

local test_dir = Path.join(tostring(Path.tempdir), "test-dir")

before_each(function()
    Path.rmdir(test_dir, true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(test_dir)
end)

after_each(function()
    Path.rmdir(test_dir, true)
    Project.root_from_path:revert()
end)

describe("end to end", function()
    it("rename", function()
        local a_path = Path.join(test_dir, "a.md")
        local a_mirror_path = Mirror(a_path):get_mirror_path("scratch")
        local b_path = Path.join(test_dir, "b.md")
        local c_path = Path.join(test_dir, "c.md")
        local c_mirror_path = Mirror(c_path):get_mirror_path("scratch")

        local a_content = {"this is", "file a"}
        Path.write(a_path, a_content)

        local b_content_old = {"text", "[ref to a](a.md)", "more text"}
        Path.write(b_path, b_content_old)

        local a_mirror_content = {"mirror content"}
        Path.write(a_mirror_path, a_mirror_content)

        local b_content_new = {"text", "[ref to a](c.md)", "more text"}

        Operator.move(a_path, c_path)

        assert.falsy(Path.exists(a_path))
        assert.falsy(Path.exists(a_mirror_path))

        assert.are.same(a_content, Path.readlines(c_path))
        assert.are.same(a_mirror_content, Path.readlines(c_mirror_path))
        assert.are.same(b_content_new, Path.readlines(b_path))
    end)
end)
