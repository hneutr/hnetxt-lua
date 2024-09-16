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
        }),
        ["adds next"] = List({
            {{"a:b"}, {"a:", "b"}},
            {{"a::b"}, {"a:", ":", "b"}},
            {{"a,b"}, {"a,", "b"}},
            {{"#a"}, {"#", "a"}},
            {{"@a"}, {"@", "a"}},

            {{"a:b"}, {"a", ":", "b"}},
            {{"a,b"}, {"a", ",", "b"}},
        }),
        ["rejects at start"] = List({
            {{"b"}, {",", "a", "b"}},
            {{"a"}, {"-", "a"}},
        }),
        ["accepts at start"] = List({
            {{":a"}, {":", "a"}},
        }),
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
