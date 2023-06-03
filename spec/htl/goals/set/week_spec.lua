local WeekSet = require("htl.goals.set.week")

describe("is_instance", function()
    it("+", function()
        assert(WeekSet:is_instance("a/b/19930120-19930126.md"))
    end)

    it("-: string", function()
        assert.falsy(WeekSet:is_instance("a/b/c.md"))
    end)

    it("-: malformed", function()
        assert.falsy(WeekSet:is_instance("a/b/19930120-a.md"))
    end)
end)

describe("is_current", function()
    it("+", function()
        assert(WeekSet:is_current(string.format("a/%s.md", WeekSet.current_stem)))
    end)

    it("-", function()
        assert.falsy(WeekSet:is_current("a/b.md"))
    end)
end)
