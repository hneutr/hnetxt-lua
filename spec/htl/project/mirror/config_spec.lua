local Config = require("htl.project.mirror.config")

local raw_category_configs = {
    sources = {
        dir = "",
        categories_to_mirror = {},
    },
    a = {
        dir = ".a",
        categories_to_mirror = {"sources"},
    },
    b = {
        dir = ".b",
        categories_to_mirror = {"a"},
    },
    c = {
        dir = ".c",
        categories_to_mirror = {"sources", "a", "b"},
    },
}

local raw_type_configs = {
    source = {category = "sources"},
    x = {category = "a", keymap_prefix = "x"},
    y = {category = "a", keymap_prefix = "y"},
    z = {category = "b", keymap_prefix = "z"},
    w = {category = "c", keymap_prefix = "w"},
}

describe("load_categories", function()
    it("+", function()
        local actual = Config.load_categories(raw_category_configs, raw_type_configs)

        for category, config in pairs(actual) do
            table.sort(config.types, function(a, b) return a < b end)
        end

        assert.are.same(
            {
                sources = {
                    dir = "",
                    categories_to_mirror = {},
                    types = {"source"},
                },
                a = {
                    dir = ".a",
                    categories_to_mirror = {"sources"},
                    types = {"x", "y"},
                },
                b = {
                    dir = ".b",
                    categories_to_mirror = {"a"},
                    types = {"z"},
                },
                c = {
                    dir = ".c",
                    categories_to_mirror = {"sources", "a", "b"},
                    types = {"w"},
                },
            },
            actual
        )
    end)
end)

describe("load_types", function()
    it("+", function()
        local category_configs = Config.load_categories(raw_category_configs, raw_type_configs)
        local actual = Config.load_types(raw_type_configs, category_configs)

        for type_name, config in pairs(actual) do
            table.sort(config.types_to_mirror)
            table.sort(config.mirror_types)
        end

        assert.are.same(
            {
                source = {
                    category = "sources",
                    dir = "",
                    types_to_mirror = {},
                    mirror_types = {"w", "x", "y"},
                },
                x = {
                    category = "a",
                    keymap_prefix = "x",
                    dir = ".a/x",
                    types_to_mirror = {"source"},
                    mirror_types = {"w", "z"},
                },
                y = {
                    category = "a",
                    keymap_prefix = "y",
                    dir = ".a/y",
                    types_to_mirror = {"source"},
                    mirror_types = {"w", "z"},
                },
                z = {
                    category = "b",
                    keymap_prefix = "z",
                    dir = ".b/z",
                    types_to_mirror = {"x", "y"},
                    mirror_types = {"w"},
                },
                w = {
                    category = "c",
                    keymap_prefix = "w",
                    dir = ".c/w",
                    types_to_mirror = {"source", "x", "y", "z"},
                    mirror_types = {},
                },
            },
            actual
        )
    end)
end)
