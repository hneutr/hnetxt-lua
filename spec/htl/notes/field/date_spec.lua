local DateField = require("htl.notes.field.date")

describe("new", function()
    it("works", function()
        local key = 'abc'
        local default = {1, 2, 3}
        local values = {1, 2, 3}
        local f = DateField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(os.date("%Y%m%d"), f.default)
        assert.are.same(nil, f.values)
    end)
end)

describe("is_of_type", function()
    it("-", function()
        assert.falsy(DateField.is_of_type({}))
    end)

    it("+", function()
        assert(DateField.is_of_type({default = os.date('%Y%m%d')}))
    end)
end)
