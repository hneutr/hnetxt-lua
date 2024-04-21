local htl = require("htl")
local Link = require("htl.text.Link")

local d1 = htl.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local give_instances_symbol = Conf.Taxonomy.relations.give_instances

local M = require("htl.Taxonomy.Parser")

before_each(function()
    htl.before_test()
    DB.projects:insert(p1)
end)

after_each(htl.after_test)

describe("parse_predicate", function()
    it("nil", function()
        assert.are.same("", M:parse_predicate())
    end)

    it("empty str", function()
        assert.are.same("", M:parse_predicate(""))
    end)

    it("no relation", function()
        assert.are.same("a", M:parse_predicate("a"))
    end)

    it("relation", function()
        local object, relation = M:parse_predicate(give_instances_symbol .. "(a)")
        assert.are.same("a", object)
        assert.are.same("give_instances", relation)
    end)

    it("relation: link", function()
        local object, relation = M:parse_predicate(give_instances_symbol .. "([a](1))")
        assert.are.same(1, object)
        assert.are.same("give_instances", relation)
    end)
end)

describe("parse_subject", function()
    it("nil", function()
        assert.are.same("", M:parse_subject())
    end)

    it("empty str", function()
        assert.are.same("", M:parse_subject())
    end)
    
    it("no predicate", function()
        assert.are.same("a", M:parse_subject("a:"))
    end)

    it("predicate", function()
        local subject, str = M:parse_subject("a: b")
        assert.are.same("a", subject)
        assert.are.same("b", str)
    end)
end)

describe("parse_taxonomy_lines", function()
    it("single line", function()
        assert.are.same(
            {
                {
                    subject_label = "a",
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
                    subject_label = "a",
                    relation = "subset",
                },
                {
                    subject_label = "a",
                    object = "b",
                    relation = "give_instances",
                }
            },
            M:parse_taxonomy_lines(List({string.format("a: %s(b)", give_instances_symbol)}))
        )
    end)

    it("multiple lines", function()
        assert.are.same(
            {
                {
                    subject_label = "a",
                    relation = "subset",
                },
                {
                    subject_label = "b",
                    object = "a",
                    relation = "subset",
                },
                {
                    subject_label = "c",
                    relation = "subset",
                },
                {
                    subject_label = "d",
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

describe("SubsetRelation", function()
    local M = M.SubsetRelation

    it("line_is_a", function()
        assert.is_false(M:line_is_a())
        assert.is_false(M:line_is_a("abc"))
        assert(M:line_is_a(M.symbol .. "abc"))
    end)
    
    describe("parse", function()
        it("one", function()
            assert.are.same(
                {"", {{subject = "a", object = 1, relation = "subset"}}},
                {M:parse(M.symbol .. tostring(Link({url = 1})), "a")}
            )
        end)
        
        it("multiple", function()
            assert.are.same(
                {
                    "",
                    {
                        {subject = "a", object = "b", relation = "subset"},
                        {subject = "b", object = "c", relation = "subset"},
                    },
                },
                {M:parse(M.symbol .. " b " .. M.symbol .. " c ", "a")}
            )
        end)
    end)
end)

describe("ConnectionRelation", function()
    local M = M.ConnectionRelation

    it("line_is_a", function()
        assert.is_false(M:line_is_a())
        assert.is_false(M:line_is_a("abc"))
        assert(M:line_is_a(M.symbol .. "abc"))
    end)

    describe("parse_one", function()
        it("object", function()
            assert.are.same({"a"}, {M:parse_one("a")})
        end)

        it("(object)", function()
            assert.are.same({"a"}, {M:parse_one("(a)")})
        end)
        it("(relation, object)", function()
            assert.are.same({"a", "b"}, {M:parse_one("(b, a)")})
        end)
    end)

    describe("parse", function()
        it("one", function()
            assert.are.same(
                {
                    "xyz",
                    {{subject = "a", object = "b", relation = "connection", type = "c"}},
                },
                {M:parse("xyz " .. M.symbol .. "(c, b)", "a")}
            )
        end)
        
        it("multiple", function()
            assert.are.same(
                {
                    "",
                    {
                        {subject = "a", object = "b", relation = "connection"},
                        {subject = "a", object = "c", relation = "connection"},
                    },
                },
                {M:parse(M.symbol .. " b " .. M.symbol .. " c ", "a")}
            )
        end)
    end)
end)

describe("GiveInstancesRelation", function()
    local M = M.GiveInstancesRelation

    it("line_is_a", function()
        assert.is_false(M:line_is_a())
        assert.is_false(M:line_is_a("abc"))
        assert(M:line_is_a(M.symbol .. "(a, b)"))
    end)

    describe("parse", function()
        it("unknown relation", function()
            assert.are.same(
                {
                    "",
                    {
                        {
                            subject = "a",
                            object = "c",
                            relation = "give_instances",
                            type = "b"
                        }
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
                        {
                            subject = "a",
                            object = "b",
                            relation = "give_instances",
                            type = "subset",
                        }
                    }
                },
                {M:parse(M.symbol .. string.format("(%s, b)", Conf.Taxonomy.relations.subset), "a")}
            )
        end)
    end)
end)
