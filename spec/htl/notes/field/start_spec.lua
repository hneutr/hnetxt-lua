local StartField = require("htl.notes.field.start")

describe("filter_value", function()
    it("+: today", function()
        assert(StartField():filter_value(tonumber(StartField.today)))
    end)

    it("+: str date", function()
        assert(StartField():filter_value(StartField.today))
    end)

    it("+: yesterday", function()
        assert(StartField():filter_value(tonumber(StartField.today) - 1))
    end)

    it("-: non-date", function()
        assert.falsy(StartField():filter_value("x"))
    end)

    it("-: tomorrow", function()
        assert.falsy(StartField():filter_value(tonumber(StartField.today) + 1))
    end)
end)

describe("filter", function()
    it("nil val", function()
        assert(StartField("key"):filter({}))
    end)

    it("non-nil val", function()
        assert(StartField("key"):filter({key = StartField.today}))
    end)

    it("bad val", function()
        assert.falsy(StartField("key"):filter({key = "x"}))
    end)
end)
