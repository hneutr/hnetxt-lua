local stub = require("luassert.stub")
local htl = require("htl")

local Link = require("htl.text.Link")
local Mirrors = require("htl.Mirrors")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file-1.md"
local f2 = d1 / "file-2.md"
local f3 = d1 / "file-3.md"

local instances_are_also_symbol = Conf.Taxonomy.relations.instances_are_also.symbol

local M = require("htl.Metadata")

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
    DB.projects:insert({title = "global", path = Conf.paths.global_taxonomy_file:parent()})
end)

after_each(htl.after_test)

describe("is_taxonomy_file", function()
    it("+: global taxonomy file", function()
        assert(M.is_taxonomy_file(Conf.paths.global_taxonomy_file))
    end)
    
    it("+: project taxonomy file", function()
        assert(M.is_taxonomy_file(d1 / Conf.paths.taxonomy_file))
    end)
    
    it("-", function()
        assert.is_false(M.is_taxonomy_file(d1))
    end)
end)

describe("parse_link", function()
    it("link", function()
        assert.are.same(1, M.Relation.parse_link(tostring(Link({label = "a", url = 1}))))
    end)
    
    it("non-link", function()
        assert.are.same("a", M.Relation.parse_link(" a "))
    end)
end)

describe("SubsetRelation", function()
    local M = M.SubsetRelation

    describe("line_is_a", function()
        it("nil", function()
            assert.is_false(M:line_is_a())
        end)
        
        it("-", function()
            assert.is_false(M:line_is_a("abc"))
        end)
        
        it("+", function()
            assert(M:line_is_a(M.symbol .. "abc"))
        end)
        it("+: middle", function()
            assert(M:line_is_a("is a: " .. M.symbol .. "abc"))
        end)
    end)

    describe("parse", function()
        it("one", function()
            assert.are.same(
                {"", {subject = "a", object = 1, relation = "subset"}},
                {M:parse(M.symbol .. tostring(Link({url = 1})), "a")}
            )
        end)
    end)
end)

describe("InstancesAreAlsoRelation", function()
    local M = M.InstancesAreAlsoRelation

    describe("line_is_a", function()
        it("nil", function()
            assert.is_false(M:line_is_a())
        end)
        
        it("-", function()
            assert.is_false(M:line_is_a("abc"))
        end)
        
        it("+", function()
            assert(M:line_is_a(M.symbol .. "(a)"))
        end)

        it("+", function()
            assert(M:line_is_a(M.symbol .. " a"))
        end)
    end)

    describe("parse", function()
        it("unknown relation", function()
            assert.are.same(
                {
                    "",
                    {
                        subject = "a",
                        object = "b",
                        relation = "instances_are_also",
                    }

                },
                {M:parse(M.symbol .. "(b)", "a")}
            )
        end)
    end)
end)

describe("InstanceRelation", function()
    local M = M.InstanceRelation
    
    describe("line_is_a", function()
        it("nil", function()
            assert.is_false(M:line_is_a())
        end)
        
        it("-", function()
            assert.is_false(M:line_is_a("abc"))
        end)
        
        it("+", function()
            assert(M:line_is_a("is a: abc"))
        end)

        it("multiple comma separated entries", function()
            assert(M:line_is_a("is a: a, b"))
        end)
    end)

    describe("parse", function()
        it("unknown relation", function()
            assert.are.same(
                {
                    "",
                    {
                        subject = "a",
                        object = "b",
                        relation = "instance",
                    }

                },
                {M:parse("b", "a")}
            )
        end)

        it("comma separated instances", function()
            assert.are.same(
                {
                    "is a: b, c",
                    {
                        subject = "a",
                        object = "d",
                        relation = "instance",
                    }

                },
                {M:parse("b, c, d", "a")}
            )
        end)
    end) 
end)

describe("TagRelation", function()
    local M = M.TagRelation
    
    describe("line_is_a", function()
        it("nil", function()
            assert.is_false(M:line_is_a())
        end)
        
        it("-", function()
            assert.is_false(M:line_is_a("abc"))
        end)
        
        it("+", function()
            assert(M:line_is_a(M.symbol .. "abc"))
        end)
    end)

    describe("parse", function()
        it("unknown relation", function()
            assert.are.same(
                {
                    "",
                    {
                        relation = "tag",
                        key = "a",
                    }

                },
                {M:parse("@a")}
            )
        end)

        describe("@link", function()
            assert.are.same(
                {
                    "",
                    {
                        relation = "tag",
                        object = 1,
                    }

                },
                {M:parse("@" .. tostring(Link({text = "xyz", url = 1})))}
            )
        end)
        
        describe("@ link", function()
            assert.are.same(
                {
                    "",
                    {
                        relation = "tag",
                        object = 1,
                    }

                },
                {M:parse("@ " .. tostring(Link({text = "xyz", url = 1})))}
            )
        end)
    end)
end)

describe("get_metadata_lines", function()
    it("works", function()
        f1:write({
            "a:",
            "b",
            "c",
            "",
            "d",
        })

        DB.urls:insert({path = f1})
        
        Mirrors:get_path(f1, "metadata"):write({"x", "y", "z"})
        
        assert.are.same(
            {"a:", "b", "c", "x", "y", "z"},
            M.get_metadata_lines(f1)
        )
    end) 
end)

describe("read_metadata_lines", function()
    it("strips line comments", function()
        f1:write({
            "a:",
            "  ~xyz",
            "b",
        })
        
        assert.are.same({"a:", "b"}, M.read_metadata_lines(f1))
    end)

    it("strips inline comments", function()
        f1:write({
            "a:",
            "b ~xyz",
        })
        
        assert.are.same({"a:", "b"}, M.read_metadata_lines(f1))
    end)
end)

describe("separate_metadata", function()
    it("whole thing", function()
        assert.are.same(
            {"a:", "b", "c", "d"},
            M.separate_metadata(List({
                "a:",
                "b",
                "c",
                "d",
            }))
        )
    end)

    it("chops", function()
        assert.are.same(
            {"@a", "b"},
            M.separate_metadata(List({
                "@a",
                "b",
                "",
                "c",
                "d",
            }))
        )
    end)
end)

describe("is_metadata_line", function()
    local F = M.is_metadata_line

    it("+: k:", function()
        assert(F("k:"))
    end)
    
    it("+: k: v", function()
        assert(F("k: v"))
    end)

    it("+: link", function()
        assert(F(tostring(Link({label = "a", url = 1}))))
    end)
    
    it("+: tag", function()
        assert(F("@abc"))
    end)
    
    it("-: too long", function()
        assert.is_false(F(string.rep("a", 500)))
    end)
    
    it("-: nil", function()
        assert.is_false(F())
    end)
    
    it("-: ''", function()
        assert.is_false(F(''))
    end)
end)

describe("parse_taxonomy_lines", function()
    it("single line", function()
        assert.are.same(
            {
                {
                    subject = "a",
                    relation = "subset",
                }
            },
            M:parse_taxonomy_lines(List({"a:"}))
        )
    end)

    it("single line + predicate", function()
        assert.are.same(
            {
                {
                    subject = "a",
                    object = "b",
                    relation = "instances_are_also",
                },
                {
                    subject = "a",
                    relation = "subset",
                },
            },
            M:parse_taxonomy_lines(List({
                string.format("a: %s(b)", instances_are_also_symbol)}
            )):sorted(function(a, b)
                return a.relation < b.relation
            end)
        )
    end)

    it("multiple lines", function()
        assert.are.same(
            {
                {
                    subject = "a",
                    relation = "subset",
                },
                {
                    subject = "b",
                    object = "a",
                    relation = "subset",
                },
                {
                    subject = "c",
                    relation = "subset",
                },
                {
                    subject = "d",
                    object = "c",
                    relation = "subset",
                },
            },
            M:parse_taxonomy_lines(List({
                "a:",
                "  b:",
                "c:",
                "  d:",
            }))
        )
    end)
end)

describe("record", function()
    it("single line", function()
        local f1 = d1 / Conf.paths.taxonomy_file
        f1:write({
            "a:",
            "  b:",
        })

        DB.urls:insert({path = f1})

        local u1 = DB.urls:where({path = f1})
        
        M:record(u1)
        
        local a_id = DB.Relations.get_url_id("a")
        local b_id = DB.Relations.get_url_id("b")

        assert.are.same(
            {
                {
                    id = 1,
                    subject = a_id,
                    relation = "subset",
                    source = u1.id,
                },
                {
                    id = 2,
                    subject = b_id,
                    object = a_id,
                    relation = "subset",
                    source = u1.id,
                },
            },
            DB.Relations:get()
        )
    end)
    
    it("multiple 'is a'", function()
        f1:write({
            "is a: x",
            "is a: y",
        })

        DB.urls:insert({path = f1})

        local u1 = DB.urls:where({path = f1})
        
        M:record(u1)
        
        local x_id = DB.Relations.get_url_id("x")
        local y_id = DB.Relations.get_url_id("y")

        assert.are.same(
            {
                {
                    id = 1,
                    subject = u1.id,
                    object = x_id,
                    relation = "instance",
                    source = u1.id,
                },
                {
                    id = 2,
                    subject = u1.id,
                    object = y_id,
                    relation = "instance",
                    source = u1.id,
                },
            },
            DB.Relations:get()
        )
    end)
end)

describe("parse_file_lines", function()
    local url = {id = 1, path = f1}

    it("is a", function()
        assert.are.same(
            {{subject = 1, object = "a", relation = "instance"}},
            M:parse_file_lines(url, List({"is a: a "}))
        )
    end)
    
    it("is a: multiple values", function()
        assert.are.same(
            {
                {subject = 1, object = "a", relation = "instance"},
                {subject = 1, object = "b", relation = "instance"}
            },
            M:parse_file_lines(url, List({"is a: b, a"}))
        )
    end)
    
    it("field: val", function()
        assert.are.same(
            {{object = 2, relation = "connection", key = "key"}},
            M:parse_file_lines(url, List({"key: [abc](2)"}))
        )
    end)
    
    it("field: {newline} val, val", function()
        assert.are.same(
            {
                {object = 2, relation = "connection", key = "key"},
                {object = 3, relation = "connection", key = "key"}
            },
            M:parse_file_lines(
                url,
                List({
                    "key:",
                    "  [abc](2)",
                    "  [def](3)",
                })
            )
        )
    end)
    
    it("nested keys", function()
        assert.are.same(
            {
                {object = 2, relation = "connection", key = "k1.k2"},
                {object = 3, relation = "connection", key = "k1.k3"}
            },
            M:parse_file_lines(
                url,
                List({
                    "k1:",
                    "  k2:",
                    "    [abc](2)",
                    "  k3:",
                    "    [abc](3)",
                })
            )
        )
    end)
    
    it("keys overwrite", function()
        assert.are.same(
            {
                {object = 2, relation = "connection", key = "k1"},
                {object = 3, relation = "connection", key = "k2"}
            },
            M:parse_file_lines(
                url,
                List({
                    "k1:",
                    "  [abc](2)",
                    "k2: [def](3)",
                    "[xyz](4)",
                })
            )
        )
    end)
    
    it("tag", function()
        assert.are.same(
            {{key = "abc", relation = "tag"}},
            M:parse_file_lines(url, List({"@abc"}))
        )
    end)
    
    it("kitchen sink", function()
        assert.are.same(
            {
                {key = "x", relation = "tag"},
                {subject = 1, object = "a", relation = "instance"},
                {object = 2, relation = "connection", key = "t1"},
                {object = 3, relation = "connection", key = "t1"}
            },
            M:parse_file_lines(
                url,
                List({
                    string.format("is a: a %s x", M.TagRelation.symbol),
                    "t1:",
                    "  [abc](2)",
                    "  [def](3)",
                })
            )
        )
    end)
end)

describe("parse_condition", function()
    local val_to_url_id = M.Relation.val_to_url_id
    
    before_each(function()
        M.Relation.val_to_url_id = function(...) return ... end
    end)
    
    after_each(function()
        M.Relation.val_to_url_id = val_to_url_id
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
        assert.are.same({"d"}, M.parse_condition("abc:d").val)
    end)

    it("multiple object", function()
        assert.are.same({"d", "e", "f"}, M.parse_condition("abc:d,e,f").val)
    end)
end)
