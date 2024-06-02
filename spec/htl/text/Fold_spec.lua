local htl = require("htl")
local Header = require("htl.text.header")

local M = require("htl.text.Fold")

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
