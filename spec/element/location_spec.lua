local Path = require("hneutil.path")
local Location = require("hnetxt-lua.element.location")
local Mark = require("hnetxt-lua.element.mark")

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

describe("__tostring", function() 
    it("+", function()
        local one = Location({path = 'a', label = 'b'})
        local two = Location({path = 'c'})
        assert.equals("a:b", tostring(one))
        assert.equals("c", tostring(two))
    end)
end)

describe("str_has_label", function()
    it("+", function()
        assert(Location.str_has_label("a:b"))
    end)

    it("+: multiple ':'", function()
        assert(Location.str_has_label("a:b: c"))
    end)

    it("-", function()
        assert.falsy(Location.str_has_label("a/b"))
    end)
end)

describe("from_str", function()
    it("no text", function()
        assert.are.same(
            Location({path = "a/b"}),
            Location.from_str("a/b")
        )
    end)

    it("text", function()
        assert.are.same(
            Location({path = "a/b", label = "c"}),
            Location.from_str("a/b:c")
        )
    end)

    it("multiple ':'", function()
        assert.are.same(
            Location({path = "a/b", label = "c: d"}),
            Location.from_str("a/b:c: d")
        )
    end)
end)

describe("get_file_locations", function()
    it("works", function()
        Path.touch(test_file)
        Path.touch(test_subfile)

        local actual = Location.get_file_locations(test_dir)
        table.sort(actual, function(a, b) return a.path:len() < b.path:len() end)

        assert.are.same(
            {
                Location({path = test_file}),
                Location({path = test_subfile})
            },
            actual
        )
    end)
end)

describe("get_mark_locations", function() 
    it("1 mark", function()
        local mark = Mark({label = 'a'})
        Path.write(test_file, tostring(mark))
        assert.are.same(
            {Location({path = test_file, label = 'a'})},
            Location.get_mark_locations(test_dir)
        )
    end)

    it("multiple marks, 1 file", function()
        local mark_a = Mark({label = 'a'})
        local mark_b = Mark({label = 'b'})
        Path.write(test_file, {tostring(mark_a), "not a mark", tostring(mark_b)})
        assert.are.same(
            {
                Location({path = test_file, label = 'a'}),
                Location({path = test_file, label = 'b'})
            },
            Location.get_mark_locations(test_dir)
        )
    end)

    it("multiple marks, multiple files", function()
        local mark_a = Mark({label = 'a'})
        local mark_b = Mark({label = 'b'})
        Path.write(test_file, {tostring(mark_a), "not a mark"})
        Path.write(test_subfile, {"not a mark", tostring(mark_b)})

        local actual = Location.get_mark_locations(test_dir)
        table.sort(actual, function(a, b) return a.path:len() < b.path:len() end)

        assert.are.same(
            {
                Location({path = test_file, label = 'a'}),
                Location({path = test_subfile, label = 'b'})
            },
            actual
        )
    end)
end)

describe("get_all_locations", function()
    it("multiple marks, multiple files", function()
        local mark_a = Mark({label = 'a'})
        local mark_b = Mark({label = 'b'})
        Path.write(test_file, {tostring(mark_a), "not a mark"})
        Path.write(test_subfile, {"not a mark", tostring(mark_b)})

        assert.are.same(
            {
                Location({path = test_file}),
                Location({path = test_file, label = 'a'}),
                Location({path = test_subfile}),
                Location({path = test_subfile, label = 'b'})
            },
            Location.get_all_locations(test_dir)
        )
    end)

    it("multiple marks, multiple files; as_str", function()
        local mark_a = Mark({label = 'a'})
        local mark_b = Mark({label = 'b'})
        Path.write(test_file, {tostring(mark_a), "not a mark"})
        Path.write(test_subfile, {"not a mark", tostring(mark_b)})

        assert.are.same(
            {
                tostring(Location({path = test_file})),
                tostring(Location({path = test_file, label = 'a'})),
                tostring(Location({path = test_subfile})),
                tostring(Location({path = test_subfile, label = 'b'}))
            },
            Location.get_all_locations(test_dir, true)
        )
    end)
end)
