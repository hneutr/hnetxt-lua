local yaml = require("hl.yaml")

local Config = require("htl.Config")

local test_dir = Config.test_root
-- local test_constants = Dict({
--     a = {x = 1},
--     ["b/c"] = {y = 2},
--     ["b/d"] = {z = 3},
-- })

before_each(function()
    Config.before_test()
end)

local function write_constants(path, content)
    path = test_dir / path
    path:write(lyaml.dump({content}))
    return path
end

after_each(function()
    Config.after_test()
end)

describe("Paths", function()
    describe("__newindex", function()
        it("works", function()
            local paths = Config.Paths.get_object({})
            assert.is_nil(paths.a)
            paths.a = 1
            assert.are.same(paths.a, 1)
        end)
    end)

    describe("__tostring", function()
        Config.root = nil
        local paths = Config.Paths.get_object({})
        assert.are.same(tostring(Dict()), tostring(paths))
        paths.a = 1
        assert.are.same(tostring(Dict({a = 1})), tostring(paths))
    end)

    describe("define", function()
        it("no parent", function()
            assert.are.same(Path("a"), Config.Paths.define("a", false, "a"))
        end)

        it("parent", function()
            assert.are.same(Path("a/b"), Config.Paths.define("b", false, "b", Path("a")))
        end)

        it("for test: file", function()
            local path = test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, Config.Paths.define("a_file", true, "a", test_dir))
            assert(path:exists())
            assert(path:is_file())
        end)

        it("for test: file", function()
            local path = test_dir / "a"
            assert.is_false(path:exists())
            assert.are.same(path, Config.Paths.define("a_dir", true, "a", test_dir))
            assert(path:exists())
            assert(path:is_dir())

        end)
    end)
end)

