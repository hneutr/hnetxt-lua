local stub = require('luassert.stub')

local Dict = require("hl.Dict")
local List = require("hl.List")
local Path = require("hl.path")

local Mirror = require("htl.mirror")
local projects = require("htl.db.projects")

local p1 = Path.tempdir

local src_r = "file.md"
local meta_r = ".notes/meta"
local src_meta_r = Path.join(meta_r, src_r)
local scratch_r = ".chaff/scratch"

local root = "root"
local meta = Path.join(root, meta_r)
local scratch = Path.join(root, scratch_r)
local src = Path.join(root, src_r)
local src_meta = Path.join(root, src_meta_r)
local src_scratch = Path.join(scratch, src_r)
local src_meta_scratch = Path.join(scratch, src_meta_r)

local all_types = Mirror.configs
local type_subset_names = List({"source", "meta", "scratch"})
local types_subset

before_each(function()
    stub(projects, 'get_path')
    projects.get_path.returns(root)

    types_subset = Dict()
    type_subset_names:foreach(function(name)
        local new_type = Dict.from(Mirror.configs[name])

        new_type.mirrors = new_type.mirrors:filter(function(subtype)
            return type_subset_names:contains(subtype)
        end)

        types_subset[name] = new_type
    end)

    Mirror.configs = types_subset

    Path.cwd():join(root):rmdir()
end)

after_each(function()
    projects.get_path:revert()
    Mirror.configs = all_types

    Path.cwd():join(root):rmdir(true)
end)

describe("makes a type", function()
    it("source", function()
        local mirror = Mirror(src)
        assert.are.equal(root, mirror.root)
        assert.are.equal(root, mirror.dir)
        assert.are.equal(src, mirror.path)
    end)

    it("source, but not relative", function()
        local mirror = Mirror(src_r)
        assert.are.equal(root, mirror.root)
        assert.are.equal(root, mirror.dir)
        assert.are.equal(src, mirror.path)
    end)

    it("scratch", function()
        local mirror = Mirror(src_scratch)
        assert.are.equal(scratch, mirror.dir)
        assert.are.equal(src_scratch, mirror.path)
    end)

    it("meta", function()
        local mirror = Mirror(src_meta)
        assert.are.equal(meta, mirror.dir)
        assert.are.equal(src_meta, mirror.path)
    end)

    it("meta scratch", function()
        local mirror = Mirror(src_meta_scratch)
        assert.are.equal(scratch, mirror.dir)
        assert.are.equal(src_meta_scratch, mirror.path)
    end)

end)

describe("path_type", function()
    it("source", function()
        assert.are.same("source", Mirror.path_type(src))
    end)

    it("meta", function()
        assert.are.same("meta", Mirror.path_type(src_meta))
    end)

    it("meta scratch", function()
        assert.are.same("scratch", Mirror.path_type(src_meta_scratch))
    end)
end)

describe("get_mirror_path", function()
    it("source → meta", function()
        assert.are.equal(src_meta, Mirror(src):get_mirror_path("meta"))
    end)

    it("meta → scratch", function()
        assert.are.equal(src_meta_scratch, Mirror(src_meta):get_mirror_path("scratch"))
    end)
end)

describe("get_mirror_paths", function()
    it("existing only", function()
        local path_exists = Path.exists
        Path.exists = function(path) return path == src_meta end

        assert.are.same({src_meta}, Mirror(src):get_mirror_paths())

        Path.exists = path_exists
    end)

    it("no mirrors", function()
        assert.are.same({}, Mirror(src_scratch):get_mirror_paths())
    end)
end)

describe("get_all_mirrored_paths", function()
    it("+", function()
        local expected = List({
            src,
            src_meta,
            src_scratch,
            src_meta_scratch,
        })

        expected:foreach(function(p) Path.touch(p) end)

        assert.are.same(
            expected,
            Mirror.get_all_mirrored_paths(src):sort(function(a, b) return #a < #b end)
        )
    end)
end)

describe("load_types", function()
    it("+", function()
        local actual = Mirror.load({
            category_mirrors = {
                sources = {},
                a = {"sources"},
                b = {"a"},
                c = {"sources", "a", "b"},
            },
            mirrors =  {
                source = {category = "sources"},
                x = {category = "a", keymap_prefix = "x"},
                y = {category = "a", keymap_prefix = "y"},
                z = {category = "b", keymap_prefix = "z"},
                w = {category = "c", keymap_prefix = "w"},
            },
        })

        actual:foreachv(function(mirror)
            mirror.to_mirror:sort()
            mirror.mirrors:sort()
        end)

        assert.are.same(
            {
                source = {
                    category = "sources",
                    dir = "",
                    to_mirror = {},
                    mirrors = {"w", "x", "y"},
                },
                x = {
                    category = "a",
                    keymap_prefix = "x",
                    dir = ".a/x",
                    to_mirror = {"source"},
                    mirrors = {"w", "z"},
                },
                y = {
                    category = "a",
                    keymap_prefix = "y",
                    dir = ".a/y",
                    to_mirror = {"source"},
                    mirrors = {"w", "z"},
                },
                z = {
                    category = "b",
                    keymap_prefix = "z",
                    dir = ".b/z",
                    to_mirror = {"x", "y"},
                    mirrors = {"w"},
                },
                w = {
                    category = "c",
                    keymap_prefix = "w",
                    dir = ".c/w",
                    to_mirror = {"source", "x", "y", "z"},
                    mirrors = {},
                },
            },
            actual
        )
    end)
end)
