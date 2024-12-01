local htl = require("htl")

local Mirrors = require("htl.Mirrors")

local M = DB.Metadata

describe("Reader", function()
    local d1 = htl.test_dir / "dir-1"
    local p1 = {title = "test", path = d1}
    local f1 = d1 / "file-1.md"

    describe("get_lines", function()
        before_each(function()
            htl.before_test()
            M = DB.Metadata

            DB.projects:insert(p1)
            DB.urls:insert({path = f1})
        end)

        after_each(htl.after_test)

        it("works", function()
            f1:write({
                "a:",
                "b",
                "c",
                "",
                "d",
            })

            Mirrors:get_path(f1, "metadata"):write({"x", "y", "z"})

            assert.are.same({"a:", "b", "c", "x", "y", "z"}, M.Reader.get_lines(f1))
        end)
    end)

    describe("read_lines", function()
        it("strips line comments", function()
            f1:write({
                "a:",
                "  ~xyz",
                "b",
            })

            assert.are.same({"a:", "b"}, M.Reader.read_lines(f1))
        end)

        it("strips inline comments", function()
            f1:write({
                "a:",
                "b ~xyz",
            })

            assert.are.same({"a:", "b"}, M.Reader.read_lines(f1))
        end)
    end)


    describe("separate_lines", function()
        UnitTest.suite(M.Reader.separate_lines, {
            ["keep"] = {input = List({"a:", "b", "c", "d"}), expected = {"a:", "b", "c", "d"}},
            ["chop"] = {input = List({"@a", "b", "", "c", "d"}), expected = {"@a", "b"}},
        })
    end)

    describe("keep_line", function()
        UnitTest.suite(M.Reader.keep_line, {
            ["k:"] = {input = "k:", expected = true},
            ["k: v"] = {input = "k: v", expected = true},
            ["link"] = {input = "[a](1)", expected = true},
            ["tag"] = {input = "@abc", expected = true},
            ["long line"] = {input = string.rep("a", 500), expected = false},
            ["nil"] = {input = nil, expected = false},
            ["empty string"] = {input = "", expected = false},
        })
    end)
end)

describe("parse_val", function()
    UnitTest.suite(M.parse_vals, {
        list = {input = [[x, y]], expected = {"x", "y"}},
        tag = {input = [[@x, y]], expected = {"x", "y"}},
        ["quoted comma (single)"] = {input = [['x, y']], expected = {"x, y"}},
        ["quoted comma (double)"] = {input = [["x, y"]], expected = {"x, y"}},
        ["list with quoted item (double)"] = {input = [['x, y', z]], expected = {"x, y", "z"}},
        ["list with quoted item (double)"] = {input = [["x, y", z]], expected = {"x, y", "z"}},
        ["list with multiple quoted items"] = {input = [["x, y", 'a, b', z]], expected = {"x, y", 'a, b', "z"}},
    })
end)

describe("parse_link", function()
    UnitTest.suite(M.parse_link, {
        ["single number"] = {input = "[abc](1)", expected = 1},
        ["multiple numbers"] = {input = "[abc](10)", expected = 10},
        ["no label"] = {input = "[](1)", expected = 1},
        ["nonlink"] = {input = "key", expected = "key"},
        ["nil"] = {input = nil, expected = nil},
    })
end)

describe("elements_to_row", function()
    UnitTest.suite(M.elements_to_row, {
        ["no strings"] = {input = {"[a](1)"}, expected = {predicate = M.conf.default_predicate, object = 1}},
        ["one string"] = {input = {"a"}, expected = {predicate = "a"}},
        ["multiple strings"] = {input = {"a", "b"}, expected = {predicate = "a.b"}},
        ["object"] = {input = {"a", "[x](1)"}, expected = {predicate = "a", object = 1}},
        ["multiple objects"] = {input = {"a", "[x](1)", "[y](2)"}, expected = nil},
    })
end)

describe("parse_elements", function()
    UnitTest.suite(M.parse_elements, {
        ["one key"] = {
            input = {"a"},
            expected = {
                {"a"},
            },
        },
        ["two keys"] = {
            input = {"a:", "b"},
            expected = {
                {"a", "b"},
            }
        },
        ["key:"] = {
            input = {"a:"},
            expected = {
                {"a"},
            }
        },
        ["two keys, first with val"] = {
            input = {"a: x, y", "b"},
            expected = {
                {"a", "x"},
                {"a", "y"},
                {"a", "b"},
            },
        },
        ["one tag"] = {
            input = {"@a"},
            expected = {{"a"}},
        },
        ["two tags"] = {
            input = {"@a, @b"},
            expected = {{"a"}, {"b"}},
        },
    })
end)

describe("parse_lines", function()
    UnitTest.suite(M.parse_lines, {
        ["key to value"] = {
            input = {"key: val"},
            expected = {{predicate = "key.val"}},
        },
        ["key to value twice"] = {
            input = {
                "a: x",
                "b: y",
            },
            expected = {
                {predicate = "a.x"},
                {predicate = "b.y"},
            },
        },
        ["key to link"] = {
            input = {"key: [a](1)"},
            expected = {{predicate = "key", object = 1}}
        },
        ["link to val"] = {
            input = {"[a](1): key"},
            expected = {{predicate = "key", object = 1}}
        },
        ["link to link"] = {
            input = {"[a](1): [b](2)"},
            expected = {},
        },
        ["bare key"] = {
            input = {"key:"},
            expected = {{predicate = "key"}},
        },
        ["key to values"] = {
            input = {"key: val1, val2"},
            expected = {
                {predicate = "key.val1"},
                {predicate = "key.val2"},
            },
        },
        ["key to val and link"] = {
            input = {"key: val, [a](1)"},
            expected = {
                {predicate = "key.val"},
                {predicate = "key", object = 1},
            },
        },
        ["key: newline val1 newline val2"] = {
            input = {
                "a:",
                "  x",
                "  y",
            },
            expected = {
                {predicate = "a.x"},
                {predicate = "a.y"},
            },
        },
        ["single tag"] = {
            input = {"@tag"},
            expected = {{predicate = "tag"}},
        },
        ["multiple tags"] = {
            input = {"@tag1, @tag2"},
            expected = {
                {predicate = "tag1"},
                {predicate = "tag2"},
            },
        },
        ["link tag"] = {
            input = {"@[a](1)"},
            expected = {{predicate = "tag", object = 1}},
        },
    })
end)

describe("Taxonomy", function()
    describe("is_taxonomy_file", function()
        local d1 = htl.test_dir / "dir-1"

        UnitTest.suite(M.Taxonomy.path_is_a, {
            ["global taxonomy file"] = {input = Conf.paths.global_taxonomy_file, expected = true},
            ["project taxonomy file"] = {input = d1 / Conf.paths.taxonomy_file, expected = true},
            ["non taxonomy"] = {input = d1, expected = false},
        })
    end)

    describe("group_to_rows", function()
        UnitTest.suite(M.Taxonomy.group_to_rows, {
            ["no object"] = {
                input = {subject = "a", elements = List()},
                expected = {},
            },
            ["object"] = {
                input = {subject = "a", object = "b", elements = List()},
                expected = {
                    {subject = "a", object = "b", predicate = "subset"},
                },
            },
            ["element with value"] = {
                input = {subject = "a", elements = List({"x: y"})},
                expected = {
                    {subject = "a", object = "y", predicate = "x"},
                },
            },
            ["element with values"] = {
                input = {subject = "a", elements = List({"x: y, [z](1)"})},
                expected = {
                    {subject = "a", object = "y", predicate = "x"},
                    {subject = "a", object = 1, predicate = "x"},
                },
            },
            ["two elements"] = {
                input = {subject = "a", elements = List({"x: y", "v: u"})},
                expected = {
                    {subject = "a", object = "y", predicate = "x"},
                    {subject = "a", object = "u", predicate = "v"},
                },
            },
        })
    end)

    describe("parse_lines", function()
        UnitTest.suite(M.Taxonomy.parse_lines, {
            ["subset"] = {
                input = {"a", "  b"},
                expected = {
                    {subject = "b", object = "a", predicate = "subset"},
                },
            },
            ["two subsets"] = {
                input = {"a", "  b", "  c"},
                expected = {
                    {subject = "b", object = "a", predicate = "subset"},
                    {subject = "c", object = "a", predicate = "subset"},
                },
            },
            ["different subsets"] = {
                input = {"a", "  b", "c", "  d"},
                expected = {
                    {subject = "b", object = "a", predicate = "subset"},
                    {subject = "d", object = "c", predicate = "subset"},
                },
            },
            ["nested subset"] = {
                input = {"a", "  b", "    c"},
                expected = {
                    {subject = "b", object = "a", predicate = "subset"},
                    {subject = "c", object = "b", predicate = "subset"},
                },
            },
            ["one element"] = {
                input = {"a", "  b", "  x: y"},
                expected = {
                    {subject = "a", object = "y", predicate = "x"},
                    {subject = "b", object = "a", predicate = "subset"},
                },
            },
            ["elements and subset elements"] = {
                input = {"a", "  x: y", "  b", "    u: v"},
                expected = {
                    {subject = "a", object = "y", predicate = "x"},
                    {subject = "b", object = "a", predicate = "subset"},
                    {subject = "b", object = "v", predicate = "u"},
                },
            },
        })
    end)
end)

describe("Row", function()
    local M = M.Row

    describe("tostring", function()
        UnitTest.suite(function(input) return M.tostring(unpack(input)) end, {
            ["nil col"] = {
                input = {{subject = "a", object = "b"}},
                expected = "a:b:" .. M.nil_val,
            },
            ["cols = str"] = {
                input = {{subject = "a", object = "b"}, "subject"},
                expected = "a",
            },
            ["cols = List(str)"] = {
                input = {{subject = "a", object = "b", predicate = "c"}, {"predicate", "subject"}},
                expected = "c:a",
            },
            ["col = table"] = {
                input = {{
                    subject = {id = 1, label = "a"},
                    object = "b",
                    predicate = "c"
                }},
                expected = "a:b:c",
            },
        })
    end)

    describe("compare_strings", function()
        UnitTest.suite(function(input) return M.compare(unpack(input)) end, {
            ["a == b"] = {
                input = {"abc", "abc"},
                expected = false,
            },
            ["x:nil == x:y"] = {
                input = {
                    ("x%s%s"):format(M.sep, M.nil_val),
                    ("x%sy"):format(M.sep),
                },
                expected = false
            },
            ["x:y == x:nil"] = {
                input = {
                    ("x%sy"):format(M.sep),
                    ("x%s%s"):format(M.sep, M.nil_val),
                },
                expected = true
            },
            ["x:y == x:z"] = {
                input = {
                    ("x%sy"):format(M.sep),
                    ("x%sz"):format(M.sep),
                },
                expected = true
            },
            ["x:z == x:y"] = {
                input = {
                    ("x%sz"):format(M.sep),
                    ("x%sy"):format(M.sep),
                },
                expected = false
            },
        })
    end)

end)

describe("db", function()
    local d1 = htl.test_dir / "dir-1"
    local p1 = {title = "test", path = d1}
    local f1 = d1 / "file-1.md"
    local f2 = d1 / "file-2.md"
    local u1
    local u2

    before_each(function()
        htl.before_test()
        M = DB.Metadata

        DB.projects:insert(p1)
        DB.urls:insert({path = f1})
        DB.urls:insert({path = f2})

        DB.projects:insert({title = "global", path = Conf.paths.global_taxonomy_file:parent()})

        u1 = DB.urls:where({path = f1}).id
        u2 = DB.urls:where({path = f2}).id
    end)

    after_each(htl.after_test)

    local idsort = function(a, b) return a.id < b.id end

    describe("taxonomy", function()
        it("taxonomy file", function()
            local f = Conf.paths.global_taxonomy_file
            local u = DB.urls:insert({path = f})

            f:write({
                "a",
                "  x: y",
                "  b",
                "",
                "test",
            })

            M.record(DB.urls:where({id = u}))

            local a_id = M.Taxonomy.get_url("a")
            local b_id = M.Taxonomy.get_url("b")
            local y_id = M.Taxonomy.get_url("y")

            assert.are.same(
                {
                    {
                        id = 1,
                        source = u,
                        subject = a_id,
                        object = y_id,
                        predicate = "x",
                    },
                    {
                        id = 2,
                        source = u,
                        subject = b_id,
                        object = a_id,
                        predicate = "subset",
                    }

                },
                DB.Metadata:get({where = {source = u}})
            )
        end)

        it("is a: taxonomy", function()
            f1:write({
                "is a: taxonomy",
                "a",
                "  x: y",
                "  b",
                "",
                "test",
            })

            M.record(DB.urls:where({id = u1}))

            local a_id = M.Taxonomy.get_url("a")
            local b_id = M.Taxonomy.get_url("b")
            local y_id = M.Taxonomy.get_url("y")

            assert.are.same(
                {
                    {
                        id = 1,
                        source = u1,
                        subject = a_id,
                        object = y_id,
                        predicate = "x",
                    },
                    {
                        id = 2,
                        source = u1,
                        subject = b_id,
                        object = a_id,
                        predicate = "subset",
                    }

                },
                DB.Metadata:get({where = {source = u1}})
            )
        end)
    end)

    describe("file", function()
        it("is a: a", function()
            f1:write({"is a: a"})

            M.record(DB.urls:where({id = u1}))

            assert.are.same(
                {
                    {
                        id = 1,
                        source = u1,
                        subject = u1,
                        object = M.Taxonomy.get_url("a"),
                        predicate = "instance",
                    },

                },
                DB.Metadata:get({where = {source = u1}})
            )
        end)

        it("metadata", function()
            f1:write({
                "is a: a",
                "x: y",
                "@z",
            })

            M.record(DB.urls:where({id = u1}))

            assert.are.same(
                {
                    {
                        id = 1,
                        source = u1,
                        subject = u1,
                        object = M.Taxonomy.get_url("a"),
                        predicate = "instance",
                    },
                    {
                        id = 2,
                        source = u1,
                        subject = u1,
                        predicate = "x.y",
                    },
                    {
                        id = 3,
                        source = u1,
                        subject = u1,
                        predicate = "z",
                    },
                },
                DB.Metadata:get({where = {source = u1}}):sort(idsort)
            )
        end)

        it("multiline", function()
            f1:write({
                "x:",
                "  y",
                "  z",
            })

            M.record(DB.urls:where({id = u1}))

            assert.are.same(
                {
                    {
                        id = 1,
                        source = u1,
                        subject = u1,
                        predicate = "x.y",
                    },
                    {
                        id = 2,
                        source = u1,
                        subject = u1,
                        predicate = "x.z",
                    },
                },
                DB.Metadata:get({where = {source = u1}}):sort(idsort)
            )
        end)
    end)
end)
