local List = require("hl.List")

local Parser = require("htl.text.neoparse")

local Divider = require("htl.text.divider")
local Header = require("htl.text.header")
local TextList = require("htl.text.list")

local parser

before_each(function()
    parser = Parser()
end)

describe("get_fold_levels", function()
    it("simple case", function()
        assert.are.same(
            {0, 0, 0, 4, 5, 4},
            parser:get_fold_levels(List.from(
                Header({size = 'large'}):get_lines(),
                {"a", "  b", "c"}
            ))
        )
    end)

    it("multiple headers", function()
        assert.are.same(
            {0, 0, 0, 4, 1, 1, 1, 1, 4, 4},
            parser:get_fold_levels(List.from(
                Header({size = 'large'}):get_lines(),
                {"a", ""},
                Header({size = 'medium'}):get_lines(),
                {"b", ""}
            ))
        )
    end)
end)

describe("get_header_indexes", function()
    it("1 header", function()
        assert.are.same(
            {2},
            parser:get_header_indexes(Header({size = 'large'}):get_lines())
        )
    end)

    it("multiple headers", function()
        assert.are.same(
            {2, 6},
            parser:get_header_indexes(List.from(
                Header({size = 'large'}):get_lines(),
                {"a"},
                Header({size = 'small'}):get_lines()
            ))
        )
    end)
end)
