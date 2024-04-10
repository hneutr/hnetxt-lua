local Parser = require("htl.Taxonomy.Parser")
local Path = require("hl.Path")

local Config = require("htl.Config")
local Urls = require("htl.db.urls")
local Link = require("htl.text.Link")

local db = require("htl.db")
local Projects = require("htl.db.projects")
local Taxa = require("htl.db.Taxa")
local Relations = require("htl.db.Relations")

local d1 = Config.test_root / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

before_each(function()
    Config.before_test()
    db.setup()
    
    Projects:insert(p1)
end)

after_each(function()
    Config.after_test()
end)

describe("parse_predicate", function()
    it("nil", function()
        assert.are.same("", Parser:parse_predicate())
    end)

    it("empty str", function()
        assert.are.same("", Parser:parse_predicate(""))
    end)

    it("no relation", function()
        assert.are.same("a", Parser:parse_predicate("a"))
    end)

    it("relation", function()
        local object, relation = Parser:parse_predicate("+(a)")
        assert.are.same("a", object)
        assert.are.same("instance taxon", relation)
    end)

    it("relation: link", function()
        local object, relation = Parser:parse_predicate("+([a](1))")
        assert.are.same(1, object)
        assert.are.same("instance taxon", relation)
    end)
end)

describe("parse_subject", function()
    it("nil", function()
        assert.are.same("", Parser:parse_subject())
    end)

    it("empty str", function()
        assert.are.same("", Parser:parse_subject())
    end)
    
    it("no predicate", function()
        assert.are.same("a", Parser:parse_subject("a:"))
    end)

    it("predicate", function()
        local subject, str = Parser:parse_subject("a: b")
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
                    object = Parser.conf.root_taxon,
                    relation = "subset of",
                }
            },
            Parser:parse_taxonomy_lines(List({"a:"}))
        )
    end)

    it("single line + predicate", function()
        assert.are.same(
            {
                {
                    subject = "a",
                    object = Parser.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "a",
                    object = "b",
                    relation = "instance taxon",
                }
            },
            Parser:parse_taxonomy_lines(List({"a: +(b)"}))
        )
    end)

    it("multiple lines", function()
        assert.are.same(
            {
                {
                    subject = "a",
                    object = Parser.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "b",
                    object = "a",
                    relation = "subset of",
                },
                {
                    subject = "c",
                    object = Parser.conf.root_taxon,
                    relation = "subset of",
                },
                {
                    subject = "d",
                    object = "c",
                    relation = "subset of",
                },
            },
            Parser:parse_taxonomy_lines(List({
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
        local a = Taxa:find("a", "test")
        local root = Taxa:find(Parser.conf.root_taxon, "test")
        
        f1:write({"a:"})
        Parser:parse_taxonomy(f1)

        assert.are.same(
            {
                {
                    id = 1,
                    subject = a.id,
                    object = root.id,
                    relation = "subset of",
                }
            },
            Relations:get()
        )
    end)
end)
