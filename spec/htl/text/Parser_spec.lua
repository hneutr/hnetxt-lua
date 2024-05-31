local htl = require("htl")

local Divider = require("htl.text.divider")
local Header = require("htl.text.header")

local M = require("htl.text.Parser")

describe("get_fold_levels", function()
    it("simple case", function()
        assert.are.same(
            {0, 0, 0, 4, 5, 4},
            M.get_fold_levels(List.from(
                Header({size = 'large'}):get_lines(),
                {"a", "  b", "c"}
            ))
        )
    end)

    it("multiple headers", function()
        assert.are.same(
            {0, 0, 0, 4, 1, 1, 1, 1, 4, 4},
            -- {0, 0, 0, 4, -1, 1, 1, 1, 4, -1},
            M.get_fold_levels(List.from(
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
            M.get_header_indexes(Header({size = 'large'}):get_lines())
        )
    end)

    it("multiple headers", function()
        assert.are.same(
            {2, 6},
            M.get_header_indexes(List.from(
                Header({size = 'large'}):get_lines(),
                {"a"},
                Header({size = 'small'}):get_lines()
            ))
        )
    end)
end)
