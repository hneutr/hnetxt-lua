local htl = require("htl")
local M = require("htl.Taxonomy")

describe("Conditions", function()
    describe("clean", function()
        UnitTest.suite(M.Condition.clean, {
            ["fold spaces"] = {input = "a   b", expected = "a b"},
            ["trim spaces"] = {input = " a b  ", expected = "a b"},
            ["remove comma spaces"] = {input = "a  , b", expected = "a,b"},
            ["remove colon spaces"] = {input = "a  : b", expected = "a:b"},
            ["remove dash spaces"] = {input = "a  -", expected = "a-"},
            ["remove exclamation spaces"] = {input = "a  !", expected = "a!"},
        })
    end)

    describe("split", function()
        UnitTest.suite(M.Condition.split, {
            ["start char ~= start"] = {input = "a#b", expected = {"a", "#", "b"}},
            ["end char ~= end"] = {input = "a-b", expected = {"a", "-", "b"}},
            ["keyval"] = {input = "a:b", expected = {"a", ":", "b"}},
            ["multiple end chars"] = {input = "a-!", expected = {"a", "-", "!"}},
        })
    end)

    describe("add_symbol", function()
        UnitTest.suite(function(args) return M.Condition.add_symbol(unpack(args)) end, {
            ["taxonomy"] = {
                input = {"taxonomy", List()},
                expected = {
                    {
                        predicate = {"instance", "subset"},
                        object = {},
                        predicate_object = {},
                        list_key = "object",
                        behavior = "append",
                        context = "taxonomy",
                    },
                },
            },
            ["recurse"] = {
                input = {"recurse", List({{}})},
                expected = {{recurse = true, behavior = "new"}},
            },
            ["exclude"] = {
                input = {"exclude", List({{}})},
                expected = {{exclude = true, behavior = "new"}},
            },
            ["keyval"] = {
                input = {"keyval", List({{list_key = "predicate"}})},
                expected = {{behavior = "append", list_key = "object"}},
            },
            ["comma"] = {
                input = {"comma", List({{behavior = "new"}})},
                expected = {{behavior = "append"}},
            },
        })
    end)

    describe("add_element", function()
        UnitTest.suite(function(args) return M.Condition.add_element(unpack(args)) end, {
            ["string + no condition"] = {
                input = {"a", List()},
                expected = {
                    {
                        predicate = {"a"},
                        object = {},
                        predicate_object = {},
                        list_key = "predicate",
                        behavior = "new",
                    },
                },
            },
            ["string + new"] = {
                input = {"a", List({{behavior = "new"}})},
                expected = {
                    {behavior = "new"},
                    {
                        predicate = {"a"},
                        object = {},
                        predicate_object = {},
                        list_key = "predicate",
                        behavior = "new",
                    },
                },
            },
            ["string + append"] = {
                input = {
                    "b",
                    List({
                        {
                            predicate = List("a"),
                            list_key = "predicate",
                            behavior = "append",
                        },
                    }),
                },
                expected = {
                    {
                        predicate = {"a", "b"},
                        list_key = "predicate",
                        behavior = "new",
                    },
                },
            },
            ["string + object"] = {
                input = {
                    "c",
                    List({
                        {
                            predicate = List({"a", "b"}),
                            predicate_object = List(),
                            list_key = "object",
                            behavior = "append",
                        },
                    }),
                },
                expected = {
                    {
                        predicate = {"a", "b"},
                        predicate_object = List({"a.c", "b.c"}),
                        list_key = "object",
                        behavior = "new",
                    },
                },
            },
            ["url, condition, predicate → new"] = {
                input = {
                    1,
                    List({
                        {list_key = "predicate"},
                    }),
                },
                expected = {
                    {list_key = "predicate"},
                    {
                        object = {1},
                        predicate = {},
                        predicate_object = {},
                        list_key = "object",
                        behavior = "new",
                    },
                },
            },
        })
    end)

    describe("query", function()
        UnitTest.suite(M.Condition.query, {
            ["objects"] = {
                input = {object = {1}},
                expected = {where = {object = {1}}},
            },
            ["predicates"] = {
                input = {predicate = List({"a", "b+", "+c+"})},
                expected = {contains = {predicate = {"a", "b*", "*c*"}}},
            },
            ["objects + predicate_objects"] = {
                input = {object = {1}, predicate_object = {"a.b"}, predicate = List({"a"})},
                expected = {where = {object = {1}, predicate = {"a"}}},
            },
            ["no objects + predicate_objects"] = {
                input = {predicate_object = List({"a.b+"}), predicate = List({"a"})},
                expected = {contains = {predicate = {"a.b*"}}},
            },
        })
    end)
end)
