local Path = require("hl.Path")
local M = require('hl.yaml')

local f = Path.tempdir:join("test.md")

before_each(function() Path.unlink(f) end)

after_each(function() Path.unlink(f) end)

describe("dump", function()
    it("outputs a clean string", function()
        assert.are.same("a: 1\n", M.dump({a = 1}))
    end)
end)

describe("load", function()
    it("works with dump", function()
        local expected = {a = 1, b = 2}
        assert.are.same(expected, M.load(M.dump(expected)))
    end)
end)

describe("write", function()
    it("works", function()
        M.write(f, {a = 1})
        assert.are.same("a: 1\n", Path.read(f))
    end)
end)

describe("read", function()
    it("works", function()
        local expected = {a = 1}
        M.write(f, expected)
        assert.are.same(expected, M.read(f))
    end)
end)

describe("write_document", function()
    it("one line of text", function()
        M.write_document(f, {a = 1}, "b")
        assert.are.same("a: 1\n\nb", Path.read(f))
    end)

    it("multiple lines of text", function()
        M.write_document(f, {a = 1}, {"b", "c"})
        assert.are.same("a: 1\n\nb\nc", Path.read(f))
    end)

    it("no text", function()
        M.write_document(f, {a = 1})
        assert.are.same("a: 1\n\n\n", Path.read(f))
    end)
end)

describe("read_document", function()
    it("works", function()
        M.write_document(f, {a = 1}, {"b", "c"})
        assert.are.same({{a = 1}, "b\nc"}, M.read_document(f))
    end)

    it("no text", function()
        M.write_document(f, {a = 1})
        assert.are.same({{a = 1}, ''}, M.read_document(f))
    end)
end)
