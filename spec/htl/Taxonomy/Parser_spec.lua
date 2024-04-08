local Parser = require("htl.Taxonomy.Parser")
local Path = require("hl.Path")

local Config = require("htl.Config")

before_each(function()
    Config.before_test()
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
        local str, relation = Parser:parse_predicate("+(a)")
        assert.are.same("a", str)
        assert.are.same("instance is a", relation)
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
