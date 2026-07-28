local htl = require("htl")
local M = require("htl.Config")

before_each(htl.before_test)
after_each(htl.after_test)

describe("Paths", function()
    describe("define", function()
        it("no parent", function()
            assert.are.same(Path("a"), M.Paths.define("a", "a"))
        end)

        it("parent", function()
            assert.are.same(Path("a/b"), M.Paths.define("b", "b", Path("a")))
        end)

        it("test file", function()
            local path = htl.test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, M.Paths.define("a_file", "a", path:parent()))
            assert(path:exists())
            assert(path:is_file())
        end)

        it("test dir", function()
            local path = htl.test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, M.Paths.define("a_dir", "a", path:parent()))
            assert(path:exists())
            assert(path:is_dir())
        end)
    end)
end)
