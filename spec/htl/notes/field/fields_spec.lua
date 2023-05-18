local Fields = require("htl.notes.field")
local StringField = require("htl.notes.field.string")
local DateField = require("htl.notes.field.date")

local field_format

describe("format", function()
    before_each(function()
        field_format = StringField.format
        StringField.format = function(key, args) return args end
    end)

    after_each(function()
        StringField.format = field_format
    end)

    it("handles a list", function()
        assert.are.same(
            {date = DateField.default, a = {}, b = {}},
            Fields.format({'a', 'b'})
        )
    end)

    it("respects date = false", function()
        assert.are.same(
            {a = {type = 'list'}},
            Fields.format({a = {type = 'list'}, date = false})
        )
    end)
end)

describe("set_metadata", function()
    it("works", function()
        local fields = Fields.get(Fields.format({
            "a",
            b = true,
            "c",
            d = false,
            e = {type = 'list', values = {1, 2, 3}}
        }))

        assert.are.same(
            {date = os.date("%Y%m%d"), a = 1, b = false, c = 3, d = false, e = {2}},
            Fields.set_metadata(fields, {a = 1, b = false, c = 3, e = 2})
        )
    end)
end)
