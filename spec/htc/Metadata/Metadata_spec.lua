require("htl")
local stub = require("luassert.stub")

local M = require("htc.Metadata")

describe("Conditions", function()
    describe("parse_prefixes", function()
        UnitTest.suite(M.Conditions.parse_prefixes, {
            ["#"] = {
                input = "#",
                expected = {
                    "",
                    {taxonomy = true, predicates = {"subset", "instance"}},
                }
            },
            ["!"] = {input = "!", expected = {"", {exclude = true}}},
            ["~"] = {input = "~", expected = {"", {recurse = true}}},
            ["skips"] = {input = "~/", expected = {"~/", {}}},
            ["multiple"] = {input = "!~a", expected = {"a", {exclude = true, recurse = true}}}
        }, {pack_output = true})
    end)

    describe("parse_infixes", function()
        UnitTest.suite(M.Conditions.parse_infixes, {
            ["starting ,"] = {input = ",a", expected = {",", "a"}},
            ["starting :"] = {input = ":a", expected = {":", "a"}},
            ["ending ,"] = {input = "a,", expected = {"a", ","}},
            ["ending :"] = {input = "a:", expected = {"a", ":"}},
            ["middle ,"] = {input = "a,b", expected = {"a", ",", "b"}},
            ["middle :"] = {input = "a:b", expected = {"a", ":", "b"}},
        })
    end)
end)
