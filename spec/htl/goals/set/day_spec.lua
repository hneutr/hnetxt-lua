local DaySet = require("htl.goals.set.day")

describe("is_instance", function()
    it("+", function()
        assert(DaySet:is_instance("a/b/19930120.md"))
    end)

    it("-: string", function()
        assert.falsy(DaySet:is_instance("a/b/c.md"))
    end)

    it("-: month", function()
        assert.falsy(DaySet:is_instance("a/b/199301.md"))
    end)
end)

describe("is_current", function()
    it("+", function()
        assert(DaySet:is_current(string.format("a/%s.md", os.date("%Y%m%d"))))
    end)

    it("-", function()
        assert.falsy(DaySet:is_current("a/b.md"))
    end)
end)
