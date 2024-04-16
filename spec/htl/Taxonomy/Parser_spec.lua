local HTL = require("htl")

local d1 = HTL.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local M = require("htl.Taxonomy.Parser")

before_each(function()
    HTL.before_test()
    DB.projects:insert(p1)
end)

after_each(HTL.after_test)

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
        local object, relation = M:parse_predicate("+(a)")
        assert.are.same("a", object)
        assert.are.same("instance taxon", relation)
    end)

    it("relation: link", function()
        local object, relation = M:parse_predicate("+([a](1))")
        assert.are.same(1, object)
        assert.are.same("instance taxon", relation)
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
                    relation = "subset of",
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
                    relation = "subset of",
                },
                {
                    subject_label = "a",
                    object = "b",
                    relation = "instance taxon",
                }
            },
            M:parse_taxonomy_lines(List({"a: +(b)"}))
        )
    end)

    it("multiple lines", function()
        assert.are.same(
            {
                {
                    subject_label = "a",
                    relation = "subset of",
                },
                {
                    subject_label = "b",
                    object = "a",
                    relation = "subset of",
                },
                {
                    subject_label = "c",
                    relation = "subset of",
                },
                {
                    subject_label = "d",
                    object = "c",
                    relation = "subset of",
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

describe("parse_taxonomy_file", function()
    it("single line", function()
        local f1 = d1 / Conf.paths.taxonomy_file
        f1:write({
            "a:",
            "  b:",
        })

        DB.urls:insert({path = f1})

        local u1 = DB.urls:where({path = f1})
        
        M:parse_taxonomy_file(f1)

        assert.are.same(
            {
                {
                    id = 1,
                    subject_url = u1.id,
                    subject_label = "a",
                    relation = "subset of",
                },
                {
                    id = 2,
                    subject_url = u1.id,
                    subject_label = "b",
                    object_label = "a",
                    relation = "subset of",
                },
            },
            DB.Relations:get()
        )
    end)
end)
