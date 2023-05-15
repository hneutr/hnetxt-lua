table = require("hl.table")
local Path = require("hl.path")
local Mirror = require("htl.project.mirror")
local Project = require("htl.project")

local project_root_from_path

local root = "root"

local source_name = "source.md"
local source_path = Path.joinpath(root, source_name)

local meta_project_dir = ".notes/meta"
local meta_dir = Path.joinpath(root, meta_project_dir)

local source_meta_project_path = Path.joinpath(meta_project_dir, source_name)
local source_meta_path = Path.joinpath(root, source_meta_project_path)

local scratch_project_dir = ".chaff/scratch"
local scratch_project_path = Path.joinpath(scratch_project_dir, source_name)
local scratch_path = Path.joinpath(root, scratch_project_path)
local scratch_dir = Path.joinpath(root, scratch_project_dir)

local fragments_project_dir = ".chaff/fragments"

local source_meta_scratch_project_path = Path.joinpath(scratch_project_dir, source_meta_project_path)
local source_meta_scratch_path = Path.joinpath(root, source_meta_scratch_project_path)

local source_meta_fragments_project_path = Path.joinpath(fragments_project_dir, source_meta_project_path)
local source_meta_fragments_path = Path.joinpath(root, source_meta_fragments_project_path)

before_each(function()
    project_root_from_path = Project.root_from_path
    Project.root_from_path = function() return root end
end)

after_each(function()
    Project.root_from_path = project_root_from_path
end)

describe("makes a type", function()
    it("source", function()
        local mirror = Mirror(source_path, "source")
        assert.are.equal(root, mirror.root)
        assert.are.equal(root, mirror.dir)
        assert.are.equal("", mirror.project_dir)
        assert.are.equal(source_path, mirror.path)
        assert.are.equal(source_name, mirror.relative_path)
        assert.are.equal(source_name, mirror.project_path)
        assert.are.equal(source_path, mirror.unmirrored_path)
    end)

    it("source, but not relative", function()
        local mirror = Mirror(source_name, "source")
        assert.are.equal(root, mirror.root)
        assert.are.equal(root, mirror.dir)
        assert.are.equal("", mirror.project_dir)
        assert.are.equal(source_path, mirror.path)
        assert.are.equal(source_name, mirror.relative_path)
        assert.are.equal(source_name, mirror.project_path)
        assert.are.equal(source_path, mirror.unmirrored_path)
    end)

    it("scratch", function()
        local mirror = Mirror(scratch_path, "scratch")
        assert.are.equal(scratch_dir, mirror.dir)
        assert.are.equal(scratch_path, mirror.path)
        assert.are.equal(scratch_project_dir, mirror.project_dir)
        assert.are.equal(source_name, mirror.relative_path)
        assert.are.equal(scratch_project_path, mirror.project_path)
        assert.are.equal(source_path, mirror.unmirrored_path)
    end)

    it("meta", function()
        local mirror = Mirror(source_meta_path, "meta")
        assert.are.equal(meta_dir, mirror.dir)
        assert.are.equal(meta_project_dir, mirror.project_dir)
        assert.are.equal(source_meta_path, mirror.path)
        assert.are.equal(source_name, mirror.relative_path)
        assert.are.equal(source_meta_project_path, mirror.project_path)
        assert.are.equal(source_path, mirror.unmirrored_path)
    end)

    it("meta scratch", function()
        local mirror = Mirror(source_meta_scratch_path, "scratch")
        assert.are.equal(scratch_dir, mirror.dir)
        assert.are.equal(scratch_project_dir, mirror.project_dir)
        assert.are.equal(source_meta_scratch_path, mirror.path)
        assert.are.equal(source_meta_project_path, mirror.relative_path)
        assert.are.equal(source_meta_scratch_project_path, mirror.project_path)
        assert.are.equal(source_meta_path, mirror.unmirrored_path)
    end)

end)

describe("path_type", function()
    it("source", function()
        local path = source_path
        assert.are.same("source", Mirror.path_type(path))
    end)

    it("meta", function()
        local path = source_meta_path
        assert.are.same("meta", Mirror.path_type(path))
    end)

    it("meta scratch", function()
        local path = source_meta_scratch_path
        assert.are.same("scratch", Mirror.path_type(path))
    end)
end)

describe("get_mirror_path", function()
    it("source → meta", function()
        local mirror = Mirror(source_path, "source")
        assert.are.equal(source_meta_path, mirror:get_mirror_path("meta"))
    end)

    it("meta → scratch", function()
        local mirror = Mirror(source_meta_path, "meta")
        assert.are.equal(source_meta_scratch_path, mirror:get_mirror_path("scratch"))
    end)
end)

describe("get_mirror_paths", function()
    it("+", function()
        local mirror = Mirror(source_meta_path, "meta")
        local actual = mirror:get_mirror_paths(false)
        table.sort(actual, function(a, b) return #a < #b end)

        assert.are.same(
            {
                source_meta_scratch_path,
                source_meta_fragments_path
            },
            actual
        )
    end)

    it("existing only", function()
        local path_exists = Path.exists

        Path.exists = function(path) return path == source_meta_path end

        local mirror = Mirror(source_path, "source")
        assert.are.same({source_meta_path}, mirror:get_mirror_paths())

        Path.exists = path_exists
    end)

    it("no mirrors", function()
        local mirror = Mirror(scratch_path)
        assert.are.same({}, mirror:get_mirror_paths(false))
    end)
end)

describe("get_all_mirrored_paths", function()
    local all_types = Mirror.type_configs
    local type_subset_names = {"source", "meta", "scratch"}
    local types_subset

    before_each(function()
        types_subset = {}
        for _, name in ipairs(type_subset_names) do
            local new_type = table.default({}, Mirror.type_configs[name])

            local _mirror_types = {}
            for i, sub_mirror_type in ipairs(new_type.mirror_types) do
                if table.list_contains(type_subset_names, sub_mirror_type) then
                    _mirror_types[#_mirror_types + 1] = sub_mirror_type
                end
            end

            new_type.mirror_types = _mirror_types

            types_subset[name] = new_type
        end

        Mirror.type_configs = types_subset
    end)

    after_each(function()
        Mirror.type_configs = all_types
        types_subset = {}
    end)

    it("+", function()
        local actual = Mirror.get_all_mirrored_paths(source_path, false)
        table.sort(actual, function(a, b) return #a < #b end)

        assert.are.same(
            {
                source_path,
                source_meta_path,
                scratch_path,
                source_meta_scratch_path,
            },
            actual
        )
    end)
end)

describe("find_updates", function()
    local all_types = Mirror.type_configs
    local type_subset_names = {"source", "meta", "scratch"}
    local types_subset

    before_each(function()
        types_subset = {}
        for _, name in ipairs(type_subset_names) do
            local new_type = table.default({}, Mirror.type_configs[name])

            local _mirror_types = {}
            for i, sub_mirror_type in ipairs(new_type.mirror_types) do
                if table.list_contains(type_subset_names, sub_mirror_type) then
                    _mirror_types[#_mirror_types + 1] = sub_mirror_type
                end
            end

            new_type.mirror_types = _mirror_types

            types_subset[name] = new_type
        end

        Mirror.type_configs = types_subset
    end)

    after_each(function()
        Mirror.type_configs = all_types
        types_subset = {}
    end)

    it("+", function()
        local old_paths = {
            source_path,
            source_meta_path,
            scratch_path,
            source_meta_scratch_path,
        }

        local expected = {}
        for _, old_path in ipairs(old_paths) do
            expected[old_path] = Path.with_stem(old_path, "target")
        end

        assert.are.same(expected, Mirror.find_updates(source_path, expected[source_path], false))
    end)


    it("+: nested", function()
        local old_paths = {
            source_path,
            source_meta_path,
            scratch_path,
            source_meta_scratch_path,
        }

        local expected = {}
        for _, old_path in ipairs(old_paths) do
            expected[old_path] = Path.with_name(old_path, "subdir/target.md")
        end

        assert.are.same(expected, Mirror.find_updates(source_path, expected[source_path], false))
    end)
end)
