local Config = require("htl.Config")
local db = require("htl.db")
local Link = require("htl.text.Link")

local d1 = Config.test_root / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local M = require("htl.Taxonomy.Parser")

before_each(function()
    Config.before_test()
    db.setup()
    
    DB.projects:insert(p1)
end)

after_each(function()
    Config.after_test()
end)

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
                    subject = "a",
                    object = M.conf.root_taxon,
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
                    subject = "a",
                    object = M.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "a",
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
                    subject = "a",
                    object = M.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "b",
                    object = "a",
                    relation = "subset of",
                },
                {
                    subject = "c",
                    object = M.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "d",
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

describe("parse_taxonomy", function()
    it("single line", function()
        local a = DB.Taxa:find("a", "test")
        local root = DB.Taxa:find(M.conf.root_taxon, "test")
        
        f1:write({"a:"})
        M:parse_taxonomy(f1)

        assert.are.same(
            {
                {
                    id = 1,
                    subject = a.id,
                    object = root.id,
                    relation = "subset of",
                }
            },
            DB.Relations:get()
        )
    end)
end)
