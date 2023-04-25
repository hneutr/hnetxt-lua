local Path = require("hneutil.path")

local Config = require("hnetxt-lua.config")
local Mark = require("hnetxt-lua.element.mark")
local Reference = require("hnetxt-lua.element.reference")
local Location = require("hnetxt-lua.element.location")

local test_dir = Path.joinpath(Path.tempdir(), "test-dir")
local test_file = Path.joinpath(test_dir, "test-file.md")

local test_subdir = Path.joinpath(test_dir, "test-subdir")
local test_subfile = Path.joinpath(test_subdir, "test-subfile.md")

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
        local path = Path.joinpath("a/b", Config.get("directory_file").name)
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

describe("get_referenced_mark_locations", function() 
    it("1 reference", function()
        local loc = Location({path = 'a/b', label = 'c'})
        local ref = Reference({label = 'c', location = loc})
        Path.write(test_file, tostring(ref))
        assert.are.same(
            {loc},
            Reference.get_referenced_mark_locations(test_dir)
        )
    end)

    it("2 references, 1 file", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'w', location = loc_2})

        Path.write(test_file, {tostring(ref_1), "non-reference", tostring(ref_2)})
        local actual = Reference.get_referenced_mark_locations(test_dir)
        table.sort(actual, function(a, b) return a.path:len() < b.path:len() end)

        assert.are.same(
            {
                loc_1,
                loc_2,
            },
            actual
        )
    end)

    it("2 references, 1 line", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'w', location = loc_2})

        Path.write(test_file, "1 " .. tostring(ref_1) .. " 2 " .. tostring(ref_2) .. " 3")
        local actual = Reference.get_referenced_mark_locations(test_dir)
        table.sort(actual, function(a, b) return a.path:len() < b.path:len() end)

        assert.are.same(
            {
                loc_1,
                loc_2,
            },
            actual
        )
    end)

    it("multiple references, multiple files", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'w', location = loc_2})

        Path.write(test_file, {tostring(ref_1), "not a reference"})
        Path.write(test_subfile, {"not a reference", tostring(ref_2)})

        local actual = Reference.get_referenced_mark_locations(test_dir)
        table.sort(actual, function(a, b) return a.path:len() < b.path:len() end)

        assert.are.same(
            {
                loc_1,
                loc_2,
            },
            actual
        )
    end)

    it("duplicate references", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local ref_1 = Reference({label = 'c', location = loc_1})

        Path.write(test_file, {tostring(ref_1), "not a reference"})
        Path.write(test_subfile, {"not a reference", tostring(ref_1)})

        local actual = Reference.get_referenced_mark_locations(test_dir)

        assert.are.same(
            {
                loc_1,
            },
            actual
        )
    end)
end)

describe("get_reference_locations", function() 
    it("1 reference", function()
        local loc = Location({path = 'a/b', label = 'c'})
        local ref = Reference({label = 'c', location = loc})
        Path.write(test_file, tostring(ref))

        local expected = {}
        expected[test_file] = {
            ["1"] = {tostring(ref)},
        }

        assert.are.same(expected, Reference.get_reference_locations(test_dir))
    end)

    it("2 references, 1 file", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'w', location = loc_2})

        Path.write(test_file, {tostring(ref_1), "non-reference", tostring(ref_2)})

        local expected = {}
        expected[test_file] = {
            ["1"] = {tostring(ref_1)},
            ["3"] = {tostring(ref_2)}
        }

        assert.are.same(expected, Reference.get_reference_locations(test_dir))
    end)

    it("2 references, 1 line", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'w', location = loc_2})

        Path.write(test_file, "1 " .. tostring(ref_1) .. " 2 " .. tostring(ref_2) .. " 3")

        local expected = {}
        expected[test_file] = {["1"] = {tostring(ref_1), tostring(ref_2)}}

        assert.are.same(expected, Reference.get_reference_locations(test_dir))
    end)

    it("multiple references, multiple files", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local loc_2 = Location({path = 'x/y/z', label = 'w'})
        local ref_1 = Reference({label = 'c', location = loc_1})
        local ref_2 = Reference({label = 'z', location = loc_2})

        Path.write(test_file, {tostring(ref_1), "not a reference"})
        Path.write(test_subfile, {"not a reference", tostring(ref_2)})

        local expected = {}
        expected[test_file] = {["1"] = {tostring(ref_1)}}
        expected[test_subfile] = {["2"] = {tostring(ref_2)}}

        assert.are.same(expected, Reference.get_reference_locations(test_dir))
    end)

    it("duplicate references", function()
        local loc_1 = Location({path = 'a/b', label = 'c'})
        local ref_1 = Reference({label = 'c', location = loc_1})

        Path.write(test_file, {tostring(ref_1), "not a reference"})
        Path.write(test_subfile, {"not a reference", tostring(ref_1)})

        local expected = {}
        expected[test_file] = {["1"] = {tostring(ref_1)}}
        expected[test_subfile] = {["2"] = {tostring(ref_1)}}

        assert.are.same(expected, Reference.get_reference_locations(test_dir))
    end)
end)
