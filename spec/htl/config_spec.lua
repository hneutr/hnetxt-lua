local HTL = require("htl")

local M = require("htl.Config")

local test_dir = HTL.test_dir

before_each(function()
    HTL.before_test()
end)

after_each(function()
    HTL.after_test()
end)

describe("Paths", function()
    describe("__newindex", function()
        it("works", function()
            local paths = M.Paths.get_object({})
            assert.is_nil(paths.a)
            paths.a = 1
            assert.are.same(paths.a, 1)
        end)
    end)

    describe("__tostring", function()
        local paths = M.Paths.get_object({})
        assert.is_nil(paths.a)
        paths.a = 1
        assert.are.same(1, paths.a)
    end)

    describe("define", function()
        it("no parent", function()
            assert.are.same(Path("a"), M.Paths.define("a", false, "a"))
        end)

        it("parent", function()
            assert.are.same(Path("a/b"), M.Paths.define("b", false, "b", Path("a")))
        end)

        it("for test: file", function()
            local path = test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, M.Paths.define("a_file", true, "a", test_dir))
            assert(path:exists())
            assert(path:is_file())
        end)

        it("for test: file", function()
            local path = test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, M.Paths.define("a_dir", true, "a", test_dir))
            assert(path:exists())
            assert(path:is_dir())
        end)
    end)
end)

