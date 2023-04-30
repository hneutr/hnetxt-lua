local stub = require('luassert.stub')

local Path = require('hneutil.path')

local DirOperation = require("hnetxt-lua.project.move.operation.dir")

after_each(function()
    mock:revert(Path)
end)

describe("map_source_to_target", function()
    before_each(function()
        stub(Path, "iterdir")
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

    before_each(function()
        mock:revert(DirOperation)
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
