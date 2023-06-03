local EndField = require("htl.notes.field.End")

describe("new", function()
    it("works", function()
        local key = 'abc'
        local default = {1, 2, 3}
        local values = {1, 2, 3}
        local f = EndField(key, {default = default, values = values})
        assert.are.same(key, f.key)
        assert.are.same("", f.default)
        assert.are.same(nil, f.values)
    end)
end)

describe("filter_value", function()
    it("+: today", function()
        assert(EndField():filter_value(tonumber(EndField.today)))
    end)

    it("+: tomorrow", function()
        assert(EndField():filter_value(tonumber(EndField.today) + 1))
    end)

    it("+: str date", function()
        assert(EndField():filter_value(EndField.today))
    end)

    it("-: yesterday", function()
        assert.falsy(EndField():filter_value(tonumber(EndField.today) - 1))
    end)

    it("-: non-date", function()
        assert.falsy(EndField():filter_value("x"))
    end)

    it("+: empty str", function()
        assert(EndField():filter_value(""))
    end)
end)

describe("filter", function()
    it("nil val", function()
        assert(EndField("key"):filter({}))
    end)

    it("non-nil val", function()
        assert(EndField("key"):filter({key = EndField.today}))
    end)

    it("bad val", function()
        assert.falsy(EndField("key"):filter({key = "x"}))
    end)
end)
