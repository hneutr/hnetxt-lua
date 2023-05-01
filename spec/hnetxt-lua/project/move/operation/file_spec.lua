--[[
TODO:
- to_mark:
    - process: test
]]
local stub = require('luassert.stub')

local Path = require('hneutil.path')

local Project = require("hnetxt-lua.project")

local Operation = require("hnetxt-lua.project.move.operation")
local Operator = require("hnetxt-lua.project.move.operator")
local FileOperation = require("hnetxt-lua.project.move.operation.file")
local Mirror = require("hnetxt-lua.project.mirror")
local Header = require("hnetxt-lua.text.header")
local Parser = require("hnetxt-lua.parse")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")

before_each(function()
    Path.rmdir(test_dir, true)
    stub(Project, 'root_from_path')
    Project.root_from_path.returns(test_dir)
end)

after_each(function()
    Path.rmdir(test_dir, true)
    Project.root_from_path:revert()
end)


describe("to_mark.map_mirrors", function()
    before_each(function()
        stub(Operation, 'map_mirrors')
    end)

    after_each(function()
        Operation.map_mirrors:revert()
    end)

    it("works", function()
        FileOperation.to_mark.map_mirrors({a = "b.md:z", c = "d.md"})
        assert.stub(Operation.map_mirrors).was_called_with({a = "b.md", c = "d.md"})
    end)
end)

describe("end to end", function()
    it("rename", function()
        local a_path = Path.joinpath(test_dir, "a.md")
        local a_mirror_path = Mirror(a_path):get_mirror_path("scratch")
        local b_path = Path.joinpath(test_dir, "b.md")
        local c_path = Path.joinpath(test_dir, "c.md")
        local c_mirror_path = Mirror(c_path):get_mirror_path("scratch")

        local a_content = {"this is", "file a"}
        Path.write(a_path, a_content)

        local b_content_old = {"text", "[ref to a](a.md)", "more text"}
        Path.write(b_path, b_content_old)

        local a_mirror_content = {"mirror content"}
        Path.write(a_mirror_path, a_mirror_content)

        local b_content_new = {"text", "[ref to a](c.md)", "more text"}

        Operator.operate(a_path, c_path, {process = true, update = true, dir = test_dir})

        assert.falsy(Path.exists(a_path))
        assert.falsy(Path.exists(a_mirror_path))

        assert.are.same(a_content, Path.readlines(c_path))
        assert.are.same(a_mirror_content, Path.readlines(c_mirror_path))
        assert.are.same(b_content_new, Path.readlines(b_path))
    end)

    it("to mark", function()
        local a_path = Path.joinpath(test_dir, "a.md")
        local a_mirror_path = Mirror(a_path):get_mirror_path("scratch")
        local b_path = Path.joinpath(test_dir, "b.md")
        local b_mirror_path = Mirror(b_path):get_mirror_path("scratch")
        local c_path = Path.joinpath(test_dir, "c.md")

        local a_content = {"this is", "file a"}
        Path.write(a_path, a_content)

        local b_content_old = table.list_extend(
            {"text", "", "more text", ""},
            tostring(Header({content = "[a]()"})),
            {"b:a content"}
        )
        Path.write(b_path, b_content_old)

        local a_mirror_content = {"a mirror content"}
        Path.write(a_mirror_path, a_mirror_content)

        local b_mirror_content = {"b mirror content"}
        Path.write(b_mirror_path, b_mirror_content)

        local c_content_old = {"[ref](a.md)"}
        local c_content_new = {"[ref](b.md:a)"}
        Path.write(c_path, c_content_old)

        local b_mark = b_path .. ":a"

        Operator.operate(a_path, b_mark, {process = true, update = true, dir = test_dir})

        assert.falsy(Path.exists(a_path))
        assert.falsy(Path.exists(a_mirror_path))

        local b_content_new = Parser.merge_line_sets({b_content_old, a_content})
        local b_mirror_content_new = Parser.merge_line_sets({b_mirror_content, a_mirror_content})

        assert.are.same(b_content_new, Path.readlines(b_path))
        assert.are.same(b_mirror_content_new, Path.readlines(b_mirror_path))
        assert.are.same(c_content_new, Path.readlines(c_path))
    end)
end)
