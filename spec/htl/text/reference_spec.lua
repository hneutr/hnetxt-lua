local Path = require("hl.Path")

local Config = require("htl.config")
local Reference = require("htl.text.reference")
local NLink = require("htl.text.NLink")
local Link = NLink.Link
local DefinitionLink = NLink.DefinitionLink

local Location = require("htl.text.location")

local test_dir = Path.join(tostring(Path.tempdir), "test-dir")
local test_file = Path.join(test_dir, "test-file.md")
local hidden_test_file = Path.join(test_dir, ".test-file.md")

local test_subdir = Path.join(test_dir, "test-subdir")
local test_subfile = Path.join(test_subdir, "test-subfile.md")

before_each(function()
    Path.rmdir(test_dir, true)
end)

after_each(function()
    Path.rmdir(test_dir, true)
end)

describe("default_label", function() 
    it("+ label", function()
        assert.equals("b C", Reference.default_label("b-C", Location({path = 'a'})))
    end)

    it("- label, + location.label", function()
        assert.equals("b", Reference.default_label("", Location({path = 'a', label = 'b'})))
    end)

    it("- label, - location.label", function()
        assert.equals("b", Reference.default_label("", Location({path = 'a/b'})))
    end)

    it("- label, - location.label, location.path.name == dir_file_stem", function()
        local path = Path.join("a/b", Config.get("directory_file").name)
        assert.equals("b", Reference.default_label("", Location({path = path})))
    end)
end)

describe("__tostring", function() 
    it("+", function()
        local one = Reference({label = 'a', location = Location({path = 'b', label = 'c'})})
        local two = Reference({label = 'x', location = Location({path = 'y', label = 'z'})})
        assert.equals("[a](b:c)", tostring(one))
        assert.equals("[x](y:z)", tostring(two))
    end)
end)

describe("str_is_a", function()
    it("+", function()
        assert(Reference.str_is_a("a [b](c) d"))
    end)

    it("-", function()
        assert.falsy(Reference.str_is_a("a b c d"))
    end)
end)

describe("from_str", function() 
    it("basic location", function()
        assert.are.same(
            Reference({
                label = 'c',
                location = Location({path = 'a/b'}),
                before = '0 ',
                after = ' 1',
            }),
            Reference.from_str("0 [c](a/b) 1")
        )
    end)

    it("location with label", function()
        assert.are.same(
            Reference({
                label = 'c',
                location = Location({path = 'a/b', label = 'c'}),
                before = '0 ',
                after = ' 1',
            }),
            Reference.from_str("0 [c](a/b:c) 1")
        )
    end)
end)

describe("get", function() 
    local dir1 = Path.tempdir:join("test-dir")
    local f1 = dir1:join("file-1.md")
    local f2 = dir1:join("file-2.md")
    local f3 = dir1:join(".file-3.md")

    local r1 = Link({label = "ref1", url = 1})
    local r2 = Link({label = "ref2", url = 2})

    before_each(function()
        dir1:rmdir(true)
    end)

    after_each(function()
        dir1:rmdir(true)
    end)

    it("1 ref", function()
        f1:write({r1})
        assert.are.same(
            {["1"] = {[tostring(f1)] = {1}}},
            Reference:get(dir1)
        )
    end)

    it("hidden file", function()
        f3:write({r1})
        assert.are.same(
            {["1"] = {[tostring(f3)] = {1}}},
            Reference:get(dir1)
        )
    end)

    it("2 refs", function()
        f1:write({r1, r2})
        assert.are.same(
            {
                ["1"] = {[tostring(f1)] = {1}},
                ["2"] = {[tostring(f1)] = {2}},
            },
            Reference:get(dir1)
        )
    end)

    it("2 refs, 1 line", function()
        f1:write(tostring(r1) .. tostring(r2))
        assert.are.same(
            {
                ["1"] = {[tostring(f1)] = {1}},
                ["2"] = {[tostring(f1)] = {1}},
            },
            Reference:get(dir1)
        )
    end)

    it("multiple files", function()
        f1:write({r1, r2})
        f2:write({r1})

        assert.are.same(
            {
                ["1"] = {
                    [tostring(f1)] = {1},
                    [tostring(f2)] = {1},
                },
                ["2"] = {[tostring(f1)] = {2}},
            },
            Reference:get(dir1)
        )
    end)
end)
