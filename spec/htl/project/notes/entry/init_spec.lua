table = require("hl.table")
local Path = require("hl.path")

local Fields = require("htl.project.notes.fields")
local Entry = require("htl.project.notes.entry")

local key = "entries"

local test_project_root = Path.joinpath(Path.tempdir(), "test-project-root")
local test_file = Path.joinpath(test_project_root, "other.md")

local test_entry_dir = Path.joinpath(test_project_root, key)
local test_entry_1 = Path.joinpath(test_entry_dir, "entry-1.md")
local test_entry_2 = Path.joinpath(test_entry_dir, "entry-2.md")

local test_entry_subdir = Path.joinpath(test_entry_dir, "subdir")
local test_entry_subdir_file = Path.joinpath(test_entry_subdir, "sub.md")

local test_entries = {test_entry_1, test_entry_2, test_file, test_entry_subdir_file}


before_each(function()
    Path.rmdir(test_project_root, true)
    for _, p in ipairs(test_entries) do
        Path.touch(p)
    end
end)

after_each(function()
    Path.rmdir(test_project_root, true)
end)

describe("format", function()
    it("works", function()
        local entries = {a = 1, b = 2}
        assert.are.same(entries, Entry.format(entries, 'b'))
    end)
end)

describe("find_items", function()
    it("works", function()
        local expected = {test_entry_1, test_entry_2}
        local actual = Entry(key, {}, {}, test_project_root):items()
        table.sort(expected)
        table.sort(actual)

        assert.are.same(expected, actual)
    end)
end)

describe("new_entry", function()
    it("works", function()
        local config = {fields = Fields.format({"a", b = true})}

        local e = Entry(key, config, {}, test_project_root)
        e:new_entry(test_entry_1)

        assert.are.same(
            {date = os.date("%Y%m%d"), b = true},
            e:get_metadata(test_entry_1)
        )
    end)
end)

describe("set_metadata", function()
    it("works", function()
        local config = {fields = Fields.format({"a", b = true, "c"})}

        local e = Entry(key, config, {}, test_project_root)
        e:new_entry(test_entry_1, {c = 3})

        e:set_metadata(test_entry_1, {a = 1, b = false})

        assert.are.same(
            {date = os.date("%Y%m%d"), a = 1, b = false, c = 3},
            e:get_metadata(test_entry_1)
        )
    end)
end)

describe("path", function()
    it("works", function()
        assert.are.same(
            Path.joinpath(test_project_root, key, "abc.md"),
            Entry(key, config, {}, test_project_root):path("abc")
        )
    end)
end)
