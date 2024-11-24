require("htl")

local M = require("htl.Metadata.Conditions")

describe("parse_affix", function()
    UnitTest.suite(function(input) return M.parse_affix(unpack(input)) end, {
        ["prefixes"] = {
            input = {"prefixes", "#abc"},
            expected = {"abc", {M.prefixes["#"]}},
        },
        ["no prefixes"] = {
            input = {"prefixes", "abc"},
            expected = {"abc", {}},
        },
        ["suffixes"] = {
            input = {"suffixes", "abc~!"},
            expected = {"abc", {M.suffixes["!"], M.suffixes["~"]}},
        },
        ["no suffixes"] = {
            input = {"suffixes", "abc"},
            expected = {"abc", {}},
        },
        ["non-string"] = {
            input = {"prefixes", {1}},
            expected = {{1}, {}},
        },
    }, {pack_output = true})
end)
