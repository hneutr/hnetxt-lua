local ListField = require("htl.project.notes.field.list")

local key = 'test-field-key'

describe("new", function()
    it("works", function()
        local default = {1, 2, 3}
        local values = {1, 2, 3}
        local f = ListField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same(values, f.values)
    end)

    it("no default", function()
        assert.are.same({}, ListField(key).default)
    end)
    it("non list default", function()
        assert.are.same({1}, ListField(key, {default = 1}).default)
    end)
end)

describe("clean", function()
    it("nil", function()
        assert.are.same({}, ListField(key):clean())
    end)

    it("str, no values", function()
        assert.are.same({"a"}, ListField(key):clean("a"))
    end)

    it("str, in values", function()
        assert.are.same({"a"}, ListField(key, {values = {"a", "b"}}):clean("a"))
    end)
    it("str, not in values", function()
        assert.are.same({}, ListField(key, {values = {"a", "b"}}):clean("c"))
    end)
end)

describe("get", function()
    it("exists", function()
        assert.are.same({1, 2}, ListField(key):get({[key] = {1, 2}}))
    end)
end)

describe("set", function()
    it("works", function()
        local metadata = {a = 1}
        ListField(key):set(metadata, 1)
        assert.are.same({a = 1, [key] = {1}}, metadata)
    end)

    it("overwrites", function()
        local metadata = {a = 1, [key] = 1}
        ListField(key):set(metadata, 2)
        assert.are.same({a = 1, [key] = {2}}, metadata)
    end)

    it("sets list", function()
        local metadata = {a = 1}
        ListField(key):set(metadata, {1, 2})
        assert.are.same({a = 1, [key] = {1, 2}}, metadata)
    end)
end)

describe("set_default", function()
    local f = ListField(key, {default = 1})

    it("sets", function()
        local metadata = {a = 2}
        f:set_default(metadata)
        assert.are.same({a = 2, [key] = f.default}, metadata)
    end)

    it("doesn't overwrite", function()
        local metadata = {a = 2, [key] = key}
        f:set_default(metadata)
        assert.are.same({a = 2, [key] = {key}}, metadata)
    end)
end)

describe("is_of_type", function()
    it("-", function()
        assert.falsy(ListField.is_of_type({}))
    end)

    it("+", function()
        assert(ListField.is_of_type({default = {1, 2, 3}}))
    end)
end)
