local Config = require("htl.Config")
local Taxonomy = require("htl.taxonomy")

local d1 = Path.tempdir:join("taxonomy-test")
local d2 = d1:join("subdir")
local t1 = d1:join(Taxonomy.file_name)
local t2 = d2:join(Taxonomy.file_name)

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
            Taxonomy:set_tree(d1)
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
        })

        assert.are.same(
            {
                a = {
                    b = {},
                    x = {},
                },
                c = {},
            },
            Taxonomy:set_tree(d2)
        )
    end)
end)

describe("set_children", function()
    it("set_children", function()
        assert.are.same(
            {
                a = {"b", "c", "d"},
                b = {},
                c = {"d"},
                d = {},
                e = {},
            },
            Taxonomy:set_children(Dict({
                a = {
                    b = {},
                    c = {
                        d = {}
                    },
                },
                e = {}
            }))
        )
    end)
end)
