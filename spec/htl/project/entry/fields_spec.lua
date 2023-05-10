local stub = require('luassert.stub')

local Fields = require("htl.project.entry.fields")
local Field = require("htl.project.entry.field")

local field_format

before_each(function()
    field_format = Field.format
    Field.format = function(key, args) return args end
end)

after_each(function()
    Field.format = field_format
end)

describe("format", function()
    it("handles a list", function()
        assert.are.same(
            {date = {}, a = {}, b = {}},
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
