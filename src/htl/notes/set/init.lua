local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local Object = require("hl.object")

local FileSet = require("htl.notes.set.file")
local TopicSet = require("htl.notes.set.topic")
local PromptSet = require("htl.notes.set.prompt")
local DatedSet = require("htl.notes.set.dated")

local Sets = {}

Sets.by_type = {
    [DatedSet.type] = DatedSet,
    [PromptSet.type] = PromptSet,
    [TopicSet.type] = TopicSet,
    [FileSet.type] = FileSet,
}

function Sets.get_class(set)
    return Sets.by_type[set.type or FileSet.type]
end

function Sets.format_config(config)
    local sets = Sets.format(config)
    sets = Sets.flatten(sets.subsets or sets)
    
    for key, set in pairs(sets) do
        set = Sets.get_class(set).format(set)
    end

    return sets
end

function Sets.flatten(sets)
    sets = sets or {}
    for key, set in pairs(sets) do
        sets[key] = set

        for subkey, subset in pairs(Sets.flatten(set.subsets)) do
            subkey = Path.joinpath(key, subkey)
            sets[subkey] = subset
        end

        sets[key].subsets = nil
    end

    return sets
end

function Sets.format_subsets(set)
    set = set or {}
    local subsets = set.subsets or {}
    if List.is_listlike(subsets) then
        for i, key in ipairs(subsets) do
            subsets[key] = {}
            subsets[i] = nil
        end
    end

    for i, key in ipairs(set) do
        subsets[key] = {}
        set[i] = nil
    end

    local set_class = Sets.get_class(set)
    for key, subset in pairs(set) do
        if not List(set_class.config_keys):contains(key) then
            subsets[key] = subset
            set[key] = nil
        end
    end

    set.subsets = subsets

    return set
end

function Sets.format(set)
    set = Sets.format_subsets(set)

    local subsets = set.subsets or {}
    local fields = set.fields or {}
    local filters = set.filters or {}
    for key, subset in pairs(subsets) do
        subset.fields = Dict(subset.fields, fields)
        subset.filters = Dict(subset.filters, filters)

        subsets[key] = Sets.format(subset)
    end

    if #Dict.keys(subsets) > 0 then
        set.subsets = subsets
    else
        set.subsets = nil
    end

    return set
end

return Sets
