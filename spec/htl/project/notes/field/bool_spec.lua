local BoolField = require("htl.project.notes.field.bool")

describe("new", function()
    it("works", function()
        local key = 'abc'
        local default = false
        local values = {1, 2, 3}
        local f = BoolField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same(default, f.default)
        assert.are.same({true, false}, f.values)
    end)
end)

describe("is_of_type", function()
    it("-", function()
        assert.falsy(BoolField.is_of_type({}))
    end)

    it("+: true", function()
        assert(BoolField.is_of_type({default = true}))
    end)

    it("+: false", function()
        assert(BoolField.is_of_type({default = false}))
    end)
end)
