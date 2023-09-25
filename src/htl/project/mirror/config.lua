local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")

local Config = require("htl.config")

local M = {}

function M.load()
    local raw = Config.get("mirror")
    local categories = M.load_categories(raw.categories, raw.types)
    return M.load_types(raw.types, categories)
end

function M.load_categories(raw_categories, raw_mirror_types)
    local categories = {}
    for name, raw_category in pairs(raw_categories) do
        categories[name] = Dict.from({types = List()}, raw_category)
    end

    for name, raw_mirror_type in pairs(raw_mirror_types) do
        categories[raw_mirror_type.category].types:append(name)
    end

    return categories
end

function M.load_types(raw_mirror_types, categories)
    local mirror_types = {}
    for name, raw_mirror_type in pairs(raw_mirror_types) do
        local mirror_type = Dict.from({types_to_mirror = List(), mirror_types = List()}, raw_mirror_type)

        local category = categories[mirror_type.category]

        mirror_type.dir = Path.join(category.dir, name)

        for _, category_to_mirror in ipairs(category.categories_to_mirror) do
            mirror_type.types_to_mirror:extend(categories[category_to_mirror].types)
        end

        mirror_types[name] = mirror_type
    end

    for name, mirror_type in pairs(mirror_types) do
        for _, type_to_mirror in ipairs(mirror_type.types_to_mirror) do
            mirror_types[type_to_mirror].mirror_types:append(name)
        end
    end

    mirror_types.source.dir = ""

    return mirror_types
end

return M
