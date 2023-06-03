local YearSet = require("htl.goals.set.year")

describe("is_instance", function()
    it("+", function()
        assert(YearSet:is_instance("a/b/1993.md"))
    end)

    it("-: string", function()
        assert.falsy(YearSet:is_instance("a/b/c.md"))
    end)

    it("-: more than year", function()
        assert.falsy(YearSet:is_instance("a/b/199301.md"))
    end)
end)

describe("is_current", function()
    it("+", function()
        assert(YearSet:is_current(string.format("a/%s.md", os.date("%Y"))))
    end)

    it("-", function()
        assert.falsy(YearSet:is_current("a/b.md"))
    end)
end)
