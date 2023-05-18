local StringField = require("htl.notes.field.string")

local key = 'test-field-key'

describe("new", function()
    it("works", function()
        local default = 'xyz'
        local values = {1, 2, 3}
        local f = StringField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same(values, f.values)
    end)
end)

describe("in_values", function()
    it("+: no values", function()
        assert(StringField(key):in_values(1))
    end)

    it("+: values", function()
        assert(StringField(key, {values = {1, 2}}):in_values(1))
    end)

    it("-", function()
        assert.falsy(StringField(key, {values = {1, 2}}):in_values(3))
    end)
end)

describe("set", function()
    it("sets", function()
        local f = StringField(key, {})
        local metadata = {a = 1}
        f:set(metadata, 2)
        assert.are.same({a = 1, [key] = 2}, metadata)
    end)

    it("doesn't set if not in values", function()
        local f = StringField(key, {values = {1}})
        local metadata = {a = 1}
        f:set(metadata, 2)
        assert.are.same({a = 1}, metadata)
    end)
end)

describe("set_default", function()
    local f = StringField(key, {default = 1})

    it("sets", function()
        local metadata = {a = 2}
        f:set_default(metadata)
        assert.are.same({a = 2, [key] = 1}, metadata)
    end)

    it("doesn't overwrite", function()
        local metadata = {a = 2, [key] = key}
        f:set_default(metadata)
        assert.are.same({a = 2, [key] = key}, metadata)
    end)
end)

describe("format", function()
    it("list", function()
        assert.are.same({values = {1, 2, 3}}, StringField.format(key, {1, 2, 3}))
    end)

    it("table", function()
        assert.are.same({type = 'string'}, StringField.format(key, {type = 'string'}))
    end)

    it("etc", function()
        assert.are.same({default = "a"}, StringField.format(key, "a"))
    end)
end)

describe("is_of_type", function()
    it("works", function()
        assert(StringField.is_of_type({}))
    end)
end)
