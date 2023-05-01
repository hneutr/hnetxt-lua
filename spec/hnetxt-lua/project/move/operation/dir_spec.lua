local stub = require('luassert.stub')

local Path = require('hneutil.path')

local Project = require("hnetxt-lua.project")
local Mirror = require("hnetxt-lua.project.mirror")
local Operator = require("hnetxt-lua.project.move.operator")

local DirOperation = require("hnetxt-lua.project.move.operation.dir")

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

describe("map_source_to_target", function()
    before_each(function()
        stub(Path, "iterdir")
    end)

    after_each(function()
        Path.iterdir:revert()
    end)

    it("works", function()
        Path.iterdir.on_call_with('a').returns({"a/@.md", "a/b/@.md", "a/x.md", "a/b/y.md"})
        local expected = {
            ["a/@.md"] =  "1/@.md", 
            ["a/b/@.md"] = "1/b/@.md",
            ["a/b/y.md"] = "1/b/y.md",
            ["a/x.md"] = "1/x.md",
        }
        assert.are.same(expected, DirOperation.map_source_to_target('a', '1'))
    end)
end)

describe(".to_files.map_source_to_target", function()
    before_each(function()
        stub(DirOperation, "map_source_to_target")
    end)

    after_each(function()
        DirOperation.map_source_to_target:revert()
    end)

    it("works", function()
        DirOperation.map_source_to_target.on_call_with('a/b', 'a').returns({
            ["a/b/@.md"] =  "a/@.md",
            ["a/b/c.md"] = "a/c.md",
        })

        local expected = {
            ["a/b/@.md"] =  "a/b.md", 
            ["a/b/c.md"] = "a/c.md",
        }
        assert.are.same(expected, DirOperation.to_files.map_source_to_target('a/b', 'a'))
    end)
end)

describe("end to end", function()
    it("rename", function()
        local dir_path_old = Path.joinpath(test_dir, "a")
        local dir_path_new = Path.joinpath(test_dir, "b")

        local file_path_old = Path.joinpath(dir_path_old, "x.md")
        local file_path_new = Path.joinpath(dir_path_new, "x.md")

        local mirror_path_old = Mirror(file_path_old):get_mirror_path("scratch")
        local mirror_path_new = Mirror(file_path_new):get_mirror_path("scratch")

        local ref_path = Path.joinpath(test_dir, "c.md")

        local content = {"this is", "file a"}
        Path.write(file_path_old, content)

        local mirror_content = {"mirror content"}
        Path.write(mirror_path_old, mirror_content)

        local ref_content_old = {"text", "[ref to a](a/x.md)", "more text"}
        local ref_content_new = {"text", "[ref to a](b/x.md)", "more text"}
        Path.write(ref_path, ref_content_old)

        Operator.operate(dir_path_old, dir_path_new)

        assert.falsy(Path.exists(dir_path_old))

        assert.are.same(content, Path.readlines(file_path_new))
        assert.are.same(mirror_content, Path.readlines(mirror_path_new))
        assert.are.same(ref_content_new, Path.readlines(ref_path))
    end)
end)
