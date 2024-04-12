local HTL = require("htl")
local Taxonomy = require("htl.metadata.Taxonomy")

local Condition = require("htl.metadata.Condition")

before_each(function()
    HTL.before_test()

    Conf.paths.global_taxonomy_file:write({
        "a:",
        "  b:",
        "    c:",
        "    d:",
        "e:",
        "  f:",
        "g:",
        "  h:",
        "    i:",
        "    j:",
        "  k:",
    })
    
    Condition.taxonomy = Taxonomy()
end)

after_each(function()
    HTL.after_test()
end)

describe("parse", function()
    it("startswith: +", function()
        assert.is_true(Condition.parse("@a").startswith)
    end)

    it("startswith: -", function()
        assert.is_false(Condition.parse("a").startswith)
    end)

    it("is_exclusion: +", function()
        local condition = Condition.parse("@a-")
        assert.is_true(condition.is_exclusion)
        assert.are.same("@a", condition.key)
    end)

    it("is_exclusion: -", function()
        local condition = Condition.parse("@a")
        assert.is_false(condition.is_exclusion)
    end)

    it("no vals", function()
        local condition = Condition.parse("a")
        assert.is_nil(condition.vals)
    end)

    it("1 val", function()
        local condition = Condition.parse("a:x")
        assert.are.same("a", condition.key)
        assert.are.same({"x"}, condition.vals)
    end)

    it("multiple vals", function()
        local condition = Condition.parse("a:x|y")
        assert.are.same("a", condition.key)
        assert.are.same({"x", "y"}, condition.vals)
    end)

    it("is_a", function()
        local condition = Condition.parse("is a: a|e")
        assert.are.same({"a", "b", "c", "d", "e", "f"}, condition.vals:sorted())
    end)
end)

describe("eval", function()
    it("condition.key: +", function()
        assert.is_true(Condition.eval({key = "a"}, {key = "a"}))
    end)

    it("condition.key: -", function()
        assert.is_false(Condition.eval({key = "a"}, {key = "b"}))
    end)

    it("condition.startswith = true: +", function()
        assert.is_true(Condition.eval({key = "abc"}, {key = "a", startswith = true}))
    end)

    it("condition.startswith = true: -", function()
        assert.is_false(Condition.eval({key = "abc"}, {key = "b", startswith = true}))
    end)

    it("condition.vals = nil, val = nil: true", function()
        assert.is_true(Condition.eval({key = "a"}, {key = "a"}))
    end)

    it("condition.vals exists, val = nil: -", function()
        assert.is_false(Condition.eval({key = "a"}, {key = "a", vals = List({"x"})}))
    end)

    it("condition.vals exists, val = mismatch: -", function()
        assert.is_false(Condition.eval({key = "a", val = "y"}, {key = "a", vals = List({"x"})}))
    end)

    it("condition.vals exists, val = match: +", function()
        assert.is_true(Condition.eval({key = "a", val = "y"}, {key = "a", vals = List({"x", "y"})}))
    end)
end)

