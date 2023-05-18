table = require("hl.table")
local Path = require("hl.path")

local Fields = require("htl.notes.field")
local FileSet = require("htl.notes.set.file")

local project_root = Path.joinpath(Path.tempdir(), "test-project-root")
local file = Path.joinpath(project_root, "other.md")

local fileset_dir = Path.joinpath(project_root, "files")
local file_1 = Path.joinpath(fileset_dir, "1.md")
local file_2 = Path.joinpath(fileset_dir, "2.md")
local file_a = Path.joinpath(fileset_dir, "a.md")
local date_file = Path.joinpath(fileset_dir, os.date("%Y%m%d") .. ".md")

local fileset_subdir = Path.joinpath(fileset_dir, "subdir")
local subfile = Path.joinpath(fileset_subdir, "sub.md")

local files = {
    file,
    file_1,
    file_2,
    file_a,
    date_file,
    subfile,
}

local fileset_files = {
    file_1,
    file_2,
    file_a,
    date_file,
}

before_each(function()
    Path.rmdir(project_root, true)
    for _, p in ipairs(files) do
        Path.touch(p)
    end
end)

after_each(function()
    Path.rmdir(project_root, true)
end)

describe("format", function()
    it("works", function()
        local set = {fields = {a = 1, b = 2}}
        assert.are.same(
            {
                fields = {
                    a = {default = 1},
                    b = {default = 2},
                    date = {default = os.date("%Y%m%d")},
                },
            },
            FileSet.format(set)
        )
    end)
end)

describe("files", function()
    it("works", function()
        local expected = fileset_files
        local actual = FileSet(fileset_dir, {}, {}, project_root):files()
        table.sort(expected)
        table.sort(actual)

        assert.are.same(expected, actual)
    end)
end)

describe("next_index", function()
    it("works", function()
        assert.are.same(3, FileSet.next_index(fileset_files))
    end)
end)

describe("format_path_to_touch", function()
    local file_set = FileSet(fileset_dir)

    it("normal", function()
        assert.are.same(file_1, file_set:get_path_to_touch(file_1))
    end)

    it("args.date", function()
        assert.are.same(
            Path.joinpath(fileset_dir, os.date("%Y%m%d") .. ".md"),
            file_set:get_path_to_touch(fileset_dir, {date = true})
        )
    end)

    it("args.next", function()
        assert.are.same(
            Path.joinpath(fileset_dir, "3.md"),
            file_set:get_path_to_touch(fileset_dir, {next = true})
        )
    end)
end)

describe("touch", function()
    local fields = Fields.format({a = true})
    local file_set = FileSet(fileset_dir, {fields = fields})

    it("works", function()
        Path.unlink(file_1)

        local path = file_set:touch(file_1)
        assert(Path.exists(path))
        assert.are.same(file_1, path)

        assert.are.same(
            {a = true, date = os.date("%Y%m%d")},
            file_set:path_file(file_1):get_metadata()
        )
    end)
end)
