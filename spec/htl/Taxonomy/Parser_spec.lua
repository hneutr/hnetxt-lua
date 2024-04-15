local HTL = require("htl")

local Link = require("htl.text.Link")

local d1 = HTL.test_dir / "dir-1"
local p1 = {title = "test", path = d1}
local f1 = d1 / "file.md"

local M = require("htl.Taxonomy.Parser")

--[[
There are two types of taxonomy:
1. global
2. local

local taxonomies extend the global taxonomy

- if an entry in a local taxonomy has a predicate:
    - create a local taxon for it

-----------------------------------[ usages ]-----------------------------------
- get the global/local taxonomy
- find a taxon's instance type (which we can do from the taxonomy)

----------------------------------------

This all has to change whenever we update a taxonomy.
- node changes happen on `DB.metadata.record_metadata`
- how do child changes work?
    - as in, when a child's parent changes, how do we propogate that?
        - record the `raw` parent information in the Relation table?
            - ie: url|string
        - then, when it comes time to get the taxonomy:
            - construct it on the fly

--------------------------------------------------------------------------------
--                                                                            --
--                                  Parsing                                   --
--                                                                            --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                               taxonomy files                               --
--------------------------------------------------------------------------------
- add a relation: 'subset of'

-----------------------------------[ global ]-----------------------------------
- default parent: root_taxon

-----------------------------------[ local ]------------------------------------
- default parent: none

--------------------------------------------------------------------------------
--                                                                            --
--                                  Reading                                   --
--                                                                            --
--------------------------------------------------------------------------------

-----------------------------------[ global ]-----------------------------------

-----------------------------------[ local ]------------------------------------
- if parent = nil:
    - if string and Global[string] exists:
        - parent = Global[string].parent


----------------------------------------

what if I record just the relations, raw?
Relations table:
    Subject: url|string
    SubjectType: "url"|"string"
    Object: url|string
    ObjectType: "url"|"string"
    Relation: ...
    Project: ...

Then, to construct a taxonomy:
1. start by constructing the global taxonomy
2. modify it with the local taxonomy

constructing a taxonomy from Relation rows:
- just add them all iteratively to the tree
- then set the attributes for the relations directly?

]]


before_each(function()
    HTL.before_test()
    DB.projects:insert(p1)
end)

after_each(function()
    HTL.after_test()
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
                    relation = "subset of",
                },
                {
                    subject = "b",
                    object = "a",
                    relation = "subset of",
                },
                {
                    subject = "c",
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

-- describe("parse_taxonomy", function()
--     it("single line", function()
--         local a = DB.Taxa:find("a", "test")
--         local root = DB.Taxa:find(M.conf.root_taxon, "test")
        
--         f1:write({"a:"})
--         M:parse_taxonomy(f1)

--         assert.are.same(
--             {
--                 {
--                     id = 1,
--                     subject = a.id,
--                     object = root.id,
--                     relation = "subset of",
--                 }
--             },
--             DB.Relations:get()
--         )
--     end)
-- end)
