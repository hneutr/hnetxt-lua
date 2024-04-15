local M = require("htl.metadata.Parser")

describe("parse", function()
    it("non-nested", function()
        assert.are.same(
            {
                a = {val = "b", datatype = "primitive", metadata = {}},
                c = {val = "d", datatype = "primitive", metadata = {}},
                ["@x"] = {datatype = "primitive", metadata = {}},
                ["@y"] = {datatype = "primitive", metadata = {}},
            },
            M:parse(List({
                "a: b",
                "c: d",
                "@x",
                "@y",
            }))
        )
    end)

    it("nested", function()
        assert.are.same(
            {
                a = {
                    val = "b",
                    datatype = "primitive", 
                    metadata = {
                        c = {val = "d", datatype = "primitive", metadata = {}},
                        ["@x"] = {datatype = "primitive", metadata = {}},
                    }
                },
                e = {val = "f", datatype = "primitive", metadata = {}},
                ["@y"] = {datatype = "primitive", metadata = {}}
            },
            M:parse(List({
                "a: b",
                "  c: d",
                "  @x",
                "e: f",
                "@y",
            }))
        )
    end)

    it("testing bare link", function()
        assert.are.same(
            {},
            M:parse(List({
                "[etymonline](https://www.etymonline.com/word/ex-)",
            }))
        )
    end)
end)

describe("parse_datatype", function()
    it("no val", function()
        local val, datatype = M:parse_datatype()
        assert.are.same({nil, "primitive"}, {val, datatype})
    end)

    it("non-link val", function()
        local val, datatype = M:parse_datatype("abc")
        assert.are.same({"abc", "primitive"}, {val, datatype})
    end)

    it("link val", function()
        local val, datatype = M:parse_datatype("[abc](123)")
        assert.are.same({"123", "reference"}, {val, datatype})
    end)
end)

describe("is_tag", function()
    it("+", function()
        assert(M:is_tag("  @a"))
    end)
    
    it("-", function()
        assert.is_false(M:is_tag("a"))
    end)

    it("-: nil", function()
        assert.is_false(M:is_tag())
    end)
end)

describe("is_field", function()
    it("+", function()
        assert(M:is_field("  a: b"))
    end)
    
    it("-", function()
        assert.is_false(M:is_field("a"))
    end)

    it("-: nil", function()
        assert.is_false(M:is_field())
    end)
end)

describe("is_exclusion", function()
    it("+", function()
        assert(M:is_exclusion("  a: b-"))
    end)
    
    it("-", function()
        assert.is_false(M:is_exclusion("a"))
    end)

    it("-: nil", function()
        assert.is_false(M:is_exclusion())
    end)
end)

describe("clean_exclusion", function()
    it("+", function()
        assert.are.same("  a: b", M:clean_exclusion("  a: b-"))
    end)
    
    it("-", function()
        assert.are.same("a", M:clean_exclusion("a"))
    end)

    it("-: nil", function()
        assert.are.same("", M:clean_exclusion())
    end)
end)

describe("parse_field", function()
    it("field, val", function()
        assert.are.same({"a", "b"}, M:parse_field("a: b"))
    end)
    
    it("no val", function()
        assert.are.same({"a", ""}, M:parse_field("a: "))
    end)

    it("nil", function()
        assert.is_nil(M:parse_field())
    end)
end)
