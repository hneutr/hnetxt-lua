local Path = require("hneutil.path")

local Config = require("hnetxt-lua.config")
local Mark = require("hnetxt-lua.text.mark")
local Reference = require("hnetxt-lua.text.reference")
local Location = require("hnetxt-lua.text.location")

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

describe("get_referenced_locations", function() 
    local loc_1 = Location({path = 'a/b', label = 'c'})
    local loc_2 = Location({path = 'x/y/z', label = 'w'})
    local ref_1 = Reference({label = 'c', location = loc_1})
    local ref_2 = Reference({label = 'w', location = loc_2})

    it("1 reference", function()
        Path.write(test_file, tostring(ref_1))
        assert.are.same(
            {[tostring(loc_1)] = {[test_file] = {1}}},
            Reference.get_referenced_locations(test_dir)
        )
    end)

    it("2 references, 1 file", function()
        Path.write(test_file, {tostring(ref_1), "non-reference", tostring(ref_2)})
        assert.are.same(
            {
                [tostring(loc_1)] = {[test_file] = {1}},
                [tostring(loc_2)] = {[test_file] = {3}},
            },
            Reference.get_referenced_locations(test_dir)
        )
    end)

    it("2 references, 1 line", function()
        Path.write(test_file, "1 " .. tostring(ref_1) .. " 2 " .. tostring(ref_2) .. " 3")
        assert.are.same(
            {
                [tostring(loc_1)] = {[test_file] = {1}},
                [tostring(loc_2)] = {[test_file] = {1}},
            },
            Reference.get_referenced_locations(test_dir)
        )
    end)

    it("multiple references, multiple files", function()
        Path.write(test_file, {tostring(ref_1), "not a reference"})
        Path.write(test_subfile, {"not a reference", tostring(ref_2)})

        assert.are.same(
            {
                [tostring(loc_1)] = {[test_file] = {1}},
                [tostring(loc_2)] = {[test_subfile] = {2}},
            },
            Reference.get_referenced_locations(test_dir)
        )
    end)
end)

describe("update_location", function() 
    it("mark", function()
        local old_loc = Location({path = 'a/b', label = 'c'})
        local new_loc = Location({path = 'x/y', label = 'z'})
        local old_ref = Reference({label = 'ref', location = old_loc})
        local new_ref = Reference({label = 'ref', location = new_loc})

        Path.write(test_file, {tostring(old_ref), "content"})

        assert.are.same(
            {
                {},
                {[Path.joinpath(test_file)] = {tostring(new_ref), "content"}}
            },
            Reference.update_location(
                tostring(old_loc),
                tostring(new_loc),
                Reference.get_referenced_locations(test_dir),
                {}
            )
        )
    end)

    it("file", function()
        local old_file_loc = Location({path = 'a/b'})
        local new_file_loc = Location({path = 'x/y'})

        local old_file_ref = Reference({label = 'file ref', location = old_file_loc})
        local new_file_ref = Reference({label = 'file ref', location = new_file_loc})

        local old_mark_loc = Location({path = 'a/b', label = 'c'})
        local new_mark_loc = Location({path = 'x/y', label = 'c'})

        local old_mark_ref = Reference({label = 'mark ref', location = old_mark_loc})
        local new_mark_ref = Reference({label = 'mark ref', location = new_mark_loc})

        Path.write(test_file, {tostring(old_file_ref), "content", tostring(old_mark_ref)})

        assert.are.same(
            {
                {},
                {[Path.joinpath(test_file)] = {tostring(new_file_ref), "content", tostring(new_mark_ref)}}
            },
            Reference.update_location(
                tostring(old_file_loc),
                tostring(new_file_loc),
                Reference.get_referenced_locations(test_dir),
                {}
            )
        )
    end)
end)

describe("update", function() 
    it("works", function()
        local locs = {
            files = {
                {
                    old = Location({path = 'a/b'}),
                    new = Location({path = 'x/y'}),
                },
                {
                    old = Location({path = 'g/h'}),
                }
            },
            marks = {
                {
                    old = Location({path = 'a/b', label = 'c'}),
                    new = Location({path = 'x/y', label = 'c'}),
                },
                {
                    old = Location({path = 'g/h', label = 'i'}),
                    new = Location({path = 'j/k', label = 'i'}),
                }
            }
        }

        local refs = {
            files = {
                {
                    old = Reference({label = 'file ref', location = locs.files[1].old}),
                    new = Reference({label = 'file ref', location = locs.files[1].new}),
                },
                {
                    old = Reference({label = 'file ref', location = locs.files[2].old}),
                },
            },
            marks = {
                {
                    old = Reference({label = 'mark 1 ref', location = locs.marks[1].old}),
                    new = Reference({label = 'mark 1 ref', location = locs.marks[1].new}),
                },
                {
                    old = Reference({label = 'mark 2 ref', location = locs.marks[2].old}),
                    new = Reference({label = 'mark 2 ref', location = locs.marks[2].new}),
                },
            },
        }

        local content = {
            [test_file] = {
                old = {
                    tostring(refs.files[1].old),
                    "abc",
                    tostring(refs.marks[1].old),
                    "def",
                    tostring(refs.files[2].old),
                    "ghi",
                    tostring(refs.marks[2].old),
                },
                new = {
                    tostring(refs.files[1].new),
                    "abc",
                    tostring(refs.marks[1].new),
                    "def",
                    tostring(refs.files[2].old),
                    "ghi",
                    tostring(refs.marks[2].new),
                }
            },
            [test_subfile] = {
                old = {
                    tostring(refs.files[2].old),
                    "123",
                    tostring(refs.marks[2].old),
                },
                new = {
                    tostring(refs.files[2].old),
                    "123",
                    tostring(refs.marks[2].new),
                }
            }
        }

        for path, content_info in pairs(content) do
            Path.write(path, content_info.old)
        end

        local location_changes = {
            [tostring(locs.files[1].old)] = tostring(locs.files[1].new),
            [tostring(locs.marks[2].old)] = tostring(locs.marks[2].new),
        }

        Reference.update_locations(location_changes, test_dir)

        for path, content_info in pairs(content) do
            assert.are.same(content_info.new, Path.readlines(path))
        end
    end)
end)
