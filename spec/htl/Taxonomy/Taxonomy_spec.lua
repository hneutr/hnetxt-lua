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

describe("parse_condition", function()
    local parse_condition_value_into_element = M.parse_condition_value_into_element
    
    before_each(function()
        M.parse_condition_value_into_element = function(...) return ... end
    end)
    
    after_each(function()
        M.parse_condition_value_into_element = parse_condition_value_into_element
    end)

    it("exclusion: +", function()
        assert(M.parse_condition("abc-").is_exclusion)
    end)

    it("recursive: +", function()
        assert(M.parse_condition("abc::xyz").is_recursive)
    end)

    it("recursive: -", function()
        assert.is_false(M.parse_condition("abc:xyz").is_recursive)
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

describe("add_condition_type_to_query", function()
    it("tag", function()
        assert.are.same(
            {contains = {type = "a*"}},
            M.add_condition_type_to_query({relation = "tag", type = "a"}, {})
        )
    end)
    
    it("non-tag, basic", function()
        assert.are.same(
            {where = {a = 1, type = "a"}},
            M.add_condition_type_to_query({type = "a"}, {where = {a = 1}})
        )
    end)
    
    it("+type", function()
        assert.are.same(
            {contains = {type = "*a"}},
            M.add_condition_type_to_query({type = "+a"}, {})
        )
    end)
    
    it("type+", function()
        assert.are.same(
            {contains = {type = "a*"}},
            M.add_condition_type_to_query({type = "a+"}, {})
        )
    end)
    
    it("+type+", function()
        assert.are.same(
            {contains = {type = "*a*"}},
            M.add_condition_type_to_query({type = "+a+"}, {})
        )
    end)
end)
