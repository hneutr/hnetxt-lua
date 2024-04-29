local htl = require("htl")
local Link = require("htl.text.Link")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local give_instances_symbol = Conf.Taxonomy.relations.give_instances.symbol

local M = require("htl.Taxonomy.Parser")

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
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

describe("ConnectionRelation", function()
    local M = M.ConnectionRelation

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
        it("with type", function()
            assert.are.same(
                {
                    "xyz",
                    {subject = "a", object = "b", relation = "connection", type = "c"},
                },
                {M:parse("xyz " .. M.symbol .. "(c, b)", "a")}
            )
        end)
        
        it("no type", function()
            assert.are.same(
                {
                    "",
                    {subject = "a", object = "b", relation = "connection"},
                },
                {M:parse(M.symbol .. " b ", "a")}
            )
        end)

        it("link", function()
            assert.are.same(
                {
                    "",
                    {subject = "a", object = 1, relation = "connection"},
                },
                {M:parse(M.symbol .. " " .. tostring(Link({text = "xyz", url = 1})), "a")}
            )
        end)
    end)
end)

describe("GiveInstancesRelation", function()
    local M = M.GiveInstancesRelation

    describe("line_is_a", function()
        it("nil", function()
            assert.is_false(M:line_is_a())
        end)
        
        it("-", function()
            assert.is_false(M:line_is_a("abc"))
        end)
        
        it("+", function()
            assert(M:line_is_a(M.symbol .. "(a, b)"))
        end)
    end)

    describe("parse", function()
        it("unknown relation", function()
            assert.are.same(
                {
                    "",
                    {
                        subject = "a",
                        object = "c",
                        relation = "give_instances",
                        type = "b"
                    }

                },
                {M:parse(M.symbol .. "(b, c)", "a")}
            )
        end)

        it("known relation", function()
            assert.are.same(
                {
                    "",
                    {

                        subject = "a",
                        object = "b",
                        relation = "give_instances",
                        type = "subset",
                    }
                },
                {M:parse(M.symbol .. string.format("(%s, b)", Conf.Taxonomy.relations.subset.symbol), "a")}
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
                        subject = "a",
                        object = "b",
                        relation = "tag",
                    }

                },
                {M:parse("b", "a")}
            )
        end)
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
                    object = "c",
                    relation = "give_instances",
                    type = "b"
                },
                {
                    subject = "a",
                    relation = "subset",
                },
            },
            M:parse_taxonomy_lines(List({
                string.format("a: %s(b, c)", give_instances_symbol)}
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

describe("record_taxonomy", function()
    it("single line", function()
        local f1 = d1 / Conf.paths.taxonomy_file
        f1:write({
            "a:",
            "  b:",
        })

        DB.urls:insert({path = f1})

        local u1 = DB.urls:where({path = f1})
        
        M:record_taxonomy(u1)

        assert.are.same(
            {
                {
                    id = 1,
                    subject = 1,
                    relation = "subset",
                },
                {
                    id = 2,
                    subject = 2,
                    object = 1,
                    relation = "subset",
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
            M:parse_file_lines(List({"is a: a "}), url)
        )
    end)
    
    it("field: val", function()
        assert.are.same(
            {{subject = 1, object = 2, relation = "connection", type = "key"}},
            M:parse_file_lines(List({"key: [abc](2)"}), url)
        )
    end)
    
    it("field: {newline} val, val", function()
        assert.are.same(
            {
                {subject = 1, object = 2, relation = "connection", type = "key"},
                {subject = 1, object = 3, relation = "connection", type = "key"}
            },
            M:parse_file_lines(
                List({
                    "key:",
                    "  [abc](2)",
                    "  [def](3)",
                }),
                url
            )
        )
    end)
    
    it("nested keys", function()
        assert.are.same(
            {
                {subject = 1, object = 2, relation = "connection", type = "k1.k2"},
                {subject = 1, object = 3, relation = "connection", type = "k1.k3"}
            },
            M:parse_file_lines(
                List({
                    "k1:",
                    "  k2:",
                    "    [abc](2)",
                    "  k3:",
                    "    [abc](3)",
                }),
                url
            )
        )
    end)
    
    it("keys overwrite", function()
        assert.are.same(
            {
                {subject = 1, object = 2, relation = "connection", type = "k1"},
                {subject = 1, object = 3, relation = "connection", type = "k2"}
            },
            M:parse_file_lines(
                List({
                    "k1:",
                    "  [abc](2)",
                    "k2: [def](3)",
                    "[xyz](4)",
                }),
                url
            )
        )
    end)
    
    it("tag", function()
        assert.are.same(
            {{subject = 1, object = "abc", relation = "tag"}},
            M:parse_file_lines(List({"@abc"}), url)
        )
    end)
    
    it("kitchen sink", function()
        assert.are.same(
            {
                {subject = 1, object = "x", relation = "connection"},
                {subject = 1, object = "a", relation = "instance"},
                {subject = 1, object = 2, relation = "connection", type = "t1"},
                {subject = 1, object = 3, relation = "connection", type = "t1"}
            },
            M:parse_file_lines(
                List({
                    string.format("is a: a %s x", M.ConnectionRelation.symbol),
                    "t1:",
                    "  [abc](2)",
                    "  [def](3)",
                }),
                url
            )
        )
    end)
end)
