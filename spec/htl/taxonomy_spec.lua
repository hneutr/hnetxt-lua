local Config = require("htl.Config")
local Taxonomy = require("htl.taxonomy")

local taxonomy_file_name = Config.get("taxonomy").file_name
local d1 = Path.tempdir:join("taxonomy-test")
local d2 = d1:join("subdir")
local t1 = d1:join(taxonomy_file_name)
local t2 = d2:join(taxonomy_file_name)

before_each(function()
    Config.before_test()
    d1:rmdir(true)
end)

after_each(function()
    Config.after_test()
    d1:rmdir(true)
end)


describe("set_tree", function()
    it("no path", function()
        Config.paths.global_taxonomy_file:write({
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
        Config.paths.global_taxonomy_file:write({
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
