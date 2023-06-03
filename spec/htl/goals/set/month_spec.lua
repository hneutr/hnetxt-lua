local MonthSet = require("htl.goals.set.month")

describe("is_instance", function()
    it("+", function()
        assert(MonthSet:is_instance("a/b/199301.md"))
    end)

    it("-: string", function()
        assert.falsy(MonthSet:is_instance("a/b/c.md"))
    end)

    it("-: day", function()
        assert.falsy(MonthSet:is_instance("a/b/19930120.md"))
    end)
end)

describe("is_current", function()
    it("+", function()
        assert(MonthSet:is_current(string.format("a/%s.md", os.date("%Y%m"))))
    end)

    it("-", function()
        assert.falsy(MonthSet:is_current("a/b.md"))
    end)
end)
