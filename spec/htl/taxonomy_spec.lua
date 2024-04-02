local Config = require("htl.Config")
local Taxonomy = require("htl.taxonomy")

local taxonomy_file = Conf.paths.taxonomy_file
local d1 = Config.test_root:join("taxonomy-test")
local d2 = d1 / "subdir"
local t1 = d1 / taxonomy_file
local t2 = d2 / taxonomy_file

before_each(function()
    Config.before_test()
end)

after_each(function()
    Config.after_test()
end)

describe("set_tree", function()
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
            Taxonomy(d1)
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
            Taxonomy(d2)
        )
    end)
end)
