local stub = require('luassert.stub')

local m = require("htl.entry.field")

local Field = m.Field
local BoolField = m.BoolField
local ListField = m.ListField
local DateField = m.DateField
local FieldConfig = m.FieldConfig

describe("Field", function()
    describe("new", function()
        local key = 'abc'
        local default = 'xyz'
        local values = {1, 2, 3}
        local f = Field(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same(values, f.values)
    end)

    describe("format", function()
        it("true: bool", function()
            assert.are.same(
                {type = 'bool', default = true},
                Field.format(true)
            )
        end)

        it("true: bool", function()
            assert.are.same(
                {type = 'bool', default = false},
                Field.format(false)
            )
        end)

        it("list: field", function()
            assert.are.same(
                {type = 'field', values = {"a", "b", "c"}},
                Field.format({"a", "b", "c"})
            )
        end)

        it("string: field", function()
            assert.are.same(
                {type = 'field', default = "abc"},
                Field.format("abc")
            )
        end)

        it("nil: field", function()
            assert.are.same(
                {type = 'field'},
                Field.format(nil)
            )
        end)

        it("table.default: true: bool", function()
            assert.are.same(
                {type = 'bool', default = true},
                Field.format({default = true})
            )
        end)

        it("table.default: false: bool", function()
            assert.are.same(
                {type = 'bool', default = false},
                Field.format({default = false})
            )
        end)

        it("table.default: list: list", function()
            assert.are.same(
                {type = 'list', default = {"a", "b", "c"}},
                Field.format({default = {"a", "b", "c"}})
            )
        end)
    end)
end)

describe("BoolField", function()
    describe("new", function()
        local key = 'abc'
        local default = false
        local values = {1, 2, 3}
        local f = BoolField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same({true, false}, f.values)
    end)
end)

describe("ListField", function()
    describe("new", function()
        local key = 'abc'
        local default = {1, 2, 3}
        local values = {1, 2, 3}
        local f = ListField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same(values, f.values)
    end)
end)

describe("DateField", function()
    describe("new", function()
        local key = 'abc'
        local default = {1, 2, 3}
        local values = {1, 2, 3}
        local f = DateField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(os.date("%Y%m%d"), f.default)
        assert.are.same(nil, f.values)
    end)
end)

describe("FieldConfig", function()
    describe("format", function()
        it("normal", function()
            assert.are.same(
                {
                    a = {type = 'bool', default = true},
                    b = {type = 'list', default = {'a', 'b'}},
                },
                FieldConfig.format({
                    a = {type = 'bool', default = true},
                    b = {type = 'list', default = {'a', 'b'}},
                    date = false,
                })
            )
        end)

        it("list shorthand", function()
            assert.are.same(
                {
                    a = {type = 'field'},
                    b = {type = 'field'},
                    date = {type = 'date'},
                },
                FieldConfig.format({"a", "b"})
            )
        end)
    end)
end)
