local htl = require("htl")
local M = require("htl.Taxonomy")

before_each(function()
    htl.before_test()
end)

after_each(htl.after_test)

describe("clean_condition", function()
    -- folds commas
    -- folds colons
    -- folds negations
    -- doesn't fuck up spaces
    it("works", function()
        Dict({
            ["a b"] = List({"a  b", " a b", "a b "}),
            ["a,b"] = List({"a, b", "a , b"}),
            ["a:b"] = List({"a: b", "a : b"}),
            ["a-"] = List({"a -", "a - "}),
        }):foreach(function(expected, inputs)
            inputs:foreach(function(input)
                assert.are.same(expected, M.clean_condition(input))
            end)
        end)
    end)
end)

describe("merge_condition", function()
    Dict({
        ["strips endswith chars"] = List({
            {{"a"}, {"a:"}},
            {{"a"}, {"a,"}},
        }),
        ["adds to previous"] = List({
            {{"a:b"}, {"a", ":b"}},
            {{"a,b"}, {"a", ",b"}},
            {{"a-"}, {"a", "-"}},

            {{"a:b", "c"}, {"a", ":b", "c"}},
            {{"a,b", "c"}, {"a", ",b", "c"}},
            {{"a-", "b"}, {"a", "-", "b"}},
            {{"a:+b"}, {"a:", "+", "b"}},
        }),
        ["adds next"] = List({
            {{"a:b"}, {"a:", "b"}},
            {{"a,b"}, {"a,", "b"}},

            {{"a:b"}, {"a", ":", "b"}},
            {{"a,b"}, {"a", ",", "b"}},
        }),
        ["rejects at start"] = List({
            {{"b"}, {",", "a", "b"}},
            {{"a"}, {"-", "a"}},
            {{"a"}, {"+", "a"}},
        }),
        ["accepts at start"] = List({
            {{":a"}, {":", "a"}},
        }),
        ["accepts :+"] = List({
            {{"a:+b"}, {"a:", "+", "b"}},
            {{":+a"}, {":", "+", "a"}},
        }),
        ["rejects + if not :+"] = List({
            {{"a"}, {"a", "+"}},
            {{"a", "b"}, {"a", "+", "b"}},
        })
    }):foreach(function(test_category, cases)
        cases:foreach(function(case)
            local expected = List(case[1])
            local input = List(case[2])
            local test_descriptor = string.format("%s: %s → %s", test_category, input, expected)
            
            it(test_descriptor, function()
                assert.are.same(expected, M.merge_conditions(input))
            end)
        end)
    end)
end)

describe("parse_condition", function()
    it("exclusion: +", function()
        assert(M.parse_condition("abc-").is_exclusion)
    end)

    it("recursive: +", function()
        assert(M.parse_condition("abc:+xyz").is_recursive)
    end)

    it("exclusion: -", function()
        assert.is_false(M.parse_condition("abc").is_exclusion)
    end)
    
    it("one object", function()
        assert.are.same({"d"}, M.parse_condition("abc:d").object)
    end)

    it("multiple object", function()
        assert.are.same({"d", "e", "f"}, M.parse_condition("abc:d,e,f").object)
    end)
end)
