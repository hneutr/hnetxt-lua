local Dict = require("hl.Dict")
local Path = require("hl.Path")
local Mirror = require("htl.project.mirror")

local Operation = require("htl.operator.operation")

local test_dir = Path.join(tostring(Path.tempdir), "test-dir")
local test_file = Path.join(test_dir, "test-file.md")
local test_dir_file = Path.join(test_dir, "@.md")
local test_subdir = Path.join(test_dir, "test-subdir")
local test_subfile = Path.join(test_subdir, "test-file.md")


before_each(function()
    Path.rmdir(test_dir, true)
end)

after_each(function()
    mock:revert(Path)

    Path.rmdir(test_dir, true)
end)

describe("map_mirrors", function()
    before_each(function()
        stub(Mirror, 'find_updates')
    end)

    after_each(function()
        Mirror.find_updates:revert()
    end)

    it("works", function()
        local ab = {['.x/a'] = '.x/b'}
        local cd = {['.x/c'] = '.x/d'}
        Mirror.find_updates.on_call_with('a', 'b').returns(ab)
        Mirror.find_updates.on_call_with('c', 'd').returns(cd)

        assert.are.same(Dict.from(ab, cd), Operation.map_mirrors({a = 'b', c = 'd'}))
    end)
end)

describe("could_be_file", function()
    it("+", function()
        assert(Operation.could_be_file("a.md"))
    end)

    it("-: dir", function()
        assert.falsy(Operation.could_be_file("a"))
    end)
end)

describe("could_be_dir", function()
    it("+", function()
        assert(Operation.could_be_dir(test_dir))
    end)

    it("-: dir but exists", function()
        Path.mkdir(test_dir)
        assert.falsy(Operation.could_be_dir(test_dir))
    end)

    it("-: file", function()
        assert.falsy(Operation.could_be_dir(test_file))
    end)
end)

describe("is_dir_file_of", function()
    it("+", function()
        assert(Operation.is_dir_file_of(test_dir_file))
    end)

    it("-", function()
        assert.falsy(Operation.is_dir_file_of(test_file))
    end)
end)

describe("dir_file_of", function()
    it("works", function()
        assert.are.same(test_dir_file, Operation.dir_file_of(test_dir))
    end)
end)

describe("dir_is_not_parent_of", function()
    it("+", function()
        Path.mkdir(test_dir)
        assert(Operation.dir_is_not_parent_of(test_dir, "a"))
    end)

    it("-: not dir", function()
        assert.falsy(Operation.dir_is_not_parent_of(test_dir, test_subdir))
    end)

    it("-: parent of", function()
        Path.mkdir(test_dir)
        assert.falsy(Operation.dir_is_not_parent_of(test_dir, test_subdir))
    end)
end)

describe("is_parent_of", function()
    it("+", function()
        assert(Operation.is_parent_of(test_dir, test_subdir))
    end)

    it("-: not parent of", function()
        assert.falsy(Operation.is_parent_of(test_dir, 'a'))
    end)
end)

describe("make_parent_of", function()
    it("works", function()
        assert.are.same(test_file, Operation.make_parent_of(test_dir, test_subfile))
    end)
end)
