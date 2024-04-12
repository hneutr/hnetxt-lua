local HTL = require("htl")
local M = require("htl.metadata.Taxonomy")

local taxonomy_file = Conf.paths.taxonomy_file
local d1 = HTL.test_dir / "taxonomy-test"
local d2 = d1 / "subdir"
local t1 = d1 / taxonomy_file
local t2 = d2 / taxonomy_file

before_each(function()
    HTL.before_test()
end)

after_each(function()
    HTL.after_test()
end)

describe("read_tree", function()
    it("no path", function()
        Conf.paths.global_taxonomy_file:write({
            "a:",
            "  b:",
            "c:"
        })

        assert.are.same(
            {
                a = {
                    b = {},
                },
                c = {},
            },
            M.read_tree(d1)
        )
    end)
    
    it("path in parent", function()
        Conf.paths.global_taxonomy_file:write({
            "a:",
            "  b:",
            "c:"
        })

        t1:write({
            "a:",
            "  x:",
            "b:",
            "  y:",
        })

        assert.are.same(
            {
                a = {
                    b = {
                        y = {},
                    },
                    x = {},
                },
                c = {},
            },
            M.read_tree(d2)
        )
    end)
end)
