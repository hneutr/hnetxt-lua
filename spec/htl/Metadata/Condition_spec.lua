require("htl")

local M = require("htl.Metadata.Condition")

describe("format_objects", function()
    UnitTest.suite(M.format_objects, {
        ["numbers only"] = {
            input = {
                predicates = List({"*"}),
                objects = List({1})
            },
            expected = {
                predicates = {},
                objects = {1},
            },
        },
        ["strings only"] = {
            input = {
                predicates = List({"a", "b"}),
                objects = List({"x", "y"}),
            },
            expected = {
                predicates = {"a.x", "a.y", "b.x", "b.y"},
                objects = {},
            },
        },
        ["numbers and strings"] = {
            input = {
                objects = List({1, "x"}),
                predicates = List({"a"}),
            },
            expected = {
                objects = {1},
                predicates = {"a"},
            },
        },
    })
end)
