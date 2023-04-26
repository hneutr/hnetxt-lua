local stub = require('luassert.stub')

local Infer = require("hnetxt-lua.project.move.infer")
local Inferrer = Infer.Inferrer
local FileCase = Infer.FileCase
local DirectoryCase = Infer.DirectoryCase

local Path = require("hneutil.path")

before_each(function()
    stub(Path, "is_file")
    stub(Path, "is_dir")
    stub(Path, "exists")
    stub(Path, "iterdir")
end)

after_each(function()
    Path.is_file:revert()
    Path.is_dir:revert()
    Path.exists:revert()
    Path.iterdir:revert()
end)

describe("liberal_is_file", function()
    it("+: extention", function()
        assert(Infer.liberal_is_file("a.md"))
    end)
    it("-: no extention", function()
        assert.falsy(Infer.liberal_is_file("a"))
    end)
end)

describe("liberal_is_dir", function()
    it("+: no extention", function()
        assert(Infer.liberal_is_dir("a"))
    end)
    it("-: extention", function()
        assert.falsy(Infer.liberal_is_dir("a.md"))
    end)
end)

describe("get_case_class", function()
    it("file", function()
        assert.are.same(FileCase, Inferrer.get_case_class("a.md"))
    end)
    it("dir", function()
        assert.are.same(DirectoryCase, Inferrer.get_case_class("a"))
    end)
end)

describe("FileCase", function()
    describe("cases", function()
        describe("rename", function()
            local case = FileCase(FileCase.cases.rename)
            it("-: not file, file", function()
                assert.falsy(case:evaluate("a", "b.md"))
            end)

            it("-: file, not file", function()
                assert.falsy(case:evaluate("a.md", "b"))
            end)

            it("+", function()
                local a = "a.md"
                local b = "b.md"
                assert.are.same({[a] = b}, case:evaluate(a, b))
            end)
        end)

        describe("move", function()
            local case = FileCase(FileCase.cases.move)
            it("-: not file, dir", function()
                Path.is_dir.on_call_with('b').returns(true)
                assert.falsy(case:evaluate("a", "b"))
            end)

            it("-: file, not dir", function()
                Path.is_dir.on_call_with('b').returns(false)
                assert.falsy(case:evaluate("a.md", "b"))
            end)

            it("+", function()
                local one = "a.md"
                local two = "b"
                Path.is_dir.on_call_with('b').returns(true)
                assert.are.same({[one] = Path.joinpath(two, one)}, case:evaluate(one, two))
            end)
            it("+: longer path", function()
                local one = "a/b.md"
                local two = "c"
                Path.is_dir.on_call_with('c').returns(true)
                assert.are.same({[one] = Path.joinpath(two, Path.name(one))}, case:evaluate(one, two))
            end)
        end)

        describe("to_dir", function()
            local case = FileCase(FileCase.cases.to_dir)
            it("-: not file, dir exists, match", function()
                Path.exists.on_call_with('a').returns(true)
                assert.falsy(case:evaluate("a", "a"))
            end)

            it("-: file, dir exists, match", function()
                Path.exists.on_call_with('a').returns(true)
                assert.falsy(case:evaluate("a.md", "a"))
            end)

            it("-: file, not dir exists, no match", function()
                Path.exists.on_call_with('b').returns(false)
                assert.falsy(case:evaluate("a.md", "b"))
            end)

            it("+", function()
                local one = "a.md"
                local two = "a"
                Path.exists.on_call_with('a').returns(false)
                assert.are.same({[one] = "a/@.md"}, case:evaluate(one, two))
            end)
        end)
    end)
end)

describe("DirectoryCase", function()
    describe("mapper", function()
        it("+", function()
            Path.iterdir.on_call_with('a').returns({"a/@.md", "a/b/@.md", "a/x.md", "a/b/y.md"})
            local expected = {
                ["a/@.md"] =  "1/@.md", 
                ["a/b/@.md"] = "1/b/@.md",
                ["a/b/y.md"] = "1/b/y.md",
                ["a/x.md"] = "1/x.md",
            }
            assert.are.same(expected, DirectoryCase.mapper('a', '1'))
        end)
    end)

    describe("cases", function()
        before_each(function()
            stub(DirectoryCase, "mapper")
        end)

        after_each(function()
            DirectoryCase.mapper:revert()
        end)

        describe("rename", function()
            local case = DirectoryCase(DirectoryCase.cases.rename)
            it("-: not dir, not dir", function()
                assert.falsy(case:evaluate("a.md", "b.md"))
            end)

            it("-: not dir, dir", function()
                assert.falsy(case:evaluate("a.md", "b"))
            end)

            it("-: dir, exists dir", function()
                Path.exists.on_call_with('b').returns(true)
                assert.falsy(case:evaluate("a", "b"))
            end)

            it("+", function()
                local a = "a"
                local b = "b"
                DirectoryCase.mapper.on_call_with('a', 'b').returns({a = 'b'})
                assert.are.same({[a] = b}, case:evaluate(a, b))
            end)
        end)

        -- describe("move", function()
        --     local case = FileCase(FileCase.cases.move)
        --     it("-: not file, dir", function()
        --         Path.is_dir.on_call_with('b').returns(true)
        --         assert.falsy(case:evaluate("a", "b"))
        --     end)

        --     it("-: file, not dir", function()
        --         Path.is_dir.on_call_with('b').returns(false)
        --         assert.falsy(case:evaluate("a.md", "b"))
        --     end)

        --     it("+", function()
        --         local one = "a.md"
        --         local two = "b"
        --         Path.is_dir.on_call_with('b').returns(true)
        --         assert.are.same({[one] = Path.joinpath(two, one)}, case:evaluate(one, two))
        --     end)
        --     it("+: longer path", function()
        --         local one = "a/b.md"
        --         local two = "c"
        --         Path.is_dir.on_call_with('c').returns(true)
        --         assert.are.same({[one] = Path.joinpath(two, Path.name(one))}, case:evaluate(one, two))
        --     end)
        -- end)

        -- describe("to_dir", function()
        --     local case = FileCase(FileCase.cases.to_dir)
        --     it("-: not file, dir exists, match", function()
        --         Path.exists.on_call_with('a').returns(true)
        --         assert.falsy(case:evaluate("a", "a"))
        --     end)

        --     it("-: file, dir exists, match", function()
        --         Path.exists.on_call_with('a').returns(true)
        --         assert.falsy(case:evaluate("a.md", "a"))
        --     end)

        --     it("-: file, not dir exists, no match", function()
        --         Path.exists.on_call_with('b').returns(false)
        --         assert.falsy(case:evaluate("a.md", "b"))
        --     end)

        --     it("+", function()
        --         local one = "a.md"
        --         local two = "a"
        --         Path.exists.on_call_with('a').returns(false)
        --         assert.are.same({[one] = "a/@.md"}, case:evaluate(one, two))
        --     end)
        -- end)
    end)
end)
