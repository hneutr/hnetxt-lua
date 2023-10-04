local yaml = require('hl.yaml')
local Path = require("hl.Path")

local test_file = Path.join(tostring(Path.tempdir), "yaml-test.md")

before_each(function()
    Path.unlink(test_file)
end)

after_each(function()
    Path.unlink(test_file)
end)

describe("dump", function()
    it("outputs a clean string", function()
        assert.are.same("a: 1\nb: 2\n", yaml.dump({a = 1, b = 2}))
    end)
end)

describe("load", function()
    it("works with dump", function()
        local expected = {a = 1, b = 2}
        assert.are.same(expected, yaml.load(yaml.dump(expected)))
    end)
end)

describe("write", function()
    it("works", function()
        yaml.write(test_file, {a = 1})
        assert.are.same("a: 1\n", Path.read(test_file))
    end)
end)

describe("read", function()
    it("works", function()
        local expected = {a = 1}
        yaml.write(test_file, expected)
        assert.are.same(expected, yaml.read(test_file))
    end)
end)

describe("write_document", function()
    it("one line of text", function()
        yaml.write_document(test_file, {a = 1}, "b")
        assert.are.same("a: 1\n\nb", Path.read(test_file))
    end)

    it("multiple lines of text", function()
        yaml.write_document(test_file, {a = 1}, {"b", "c"})
        assert.are.same("a: 1\n\nb\nc", Path.read(test_file))
    end)

    it("no text", function()
        yaml.write_document(test_file, {a = 1})
        assert.are.same("a: 1\n\n\n", Path.read(test_file))
    end)
end)

describe("read_document", function()
    it("works", function()
        yaml.write_document(test_file, {a = 1}, {"b", "c"})
        assert.are.same({{a = 1}, "b\nc"}, yaml.read_document(test_file))
    end)

    it("no text", function()
        yaml.write_document(test_file, {a = 1})
        assert.are.same({{a = 1}, '\n'}, yaml.read_document(test_file))
    end)
end)
