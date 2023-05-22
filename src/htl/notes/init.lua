local Path = require("hl.path")
local Dict = require("hl.Dict")
local Object = require("hl.object")

local Project = require("htl.project")
local Fields = require("htl.notes.field")
local Sets = require("htl.notes.set")

local Notes = Object:extend()

function Notes.sets(path)
    local project = Project.from_path(path)
    local configs = Sets.format_config(project.metadata.notes)

    local sets = {}
    for set_key, config in pairs(configs) do
        set_path = Path.joinpath(project.root, set_key)
        sets[set_path] = Sets.get_class(config)(set_path, config)
    end

    return sets
end

function Notes.path_set(path)
    local sets = Notes.sets(path)
    local set_paths = Dict.keys(sets)

    table.sort(set_paths, function(a, b) return #a > #b end)

    for _, set_path in pairs(set_paths) do
        if set_path == path or Path.is_relative_to(path, set_path) then
            return sets[set_path]
        end
    end
end

function Notes.path_sets(path)
    local sets = Dict()
    for set_path, set in pairs(Notes.sets(path)) do
        if set_path == path or Path.is_relative_to(set_path, path) then
            sets[set_path] = set
        end
    end

    if #sets:keys() == 0 then
        local set = Notes.path_set(path)
        sets[set.path] = set
    end

    return sets
end

function Notes.path_files(path)
    local files = List()
    for _, note_set in pairs(Notes.path_sets(path)) do
        for _, note_path in ipairs(note_set:files(path)) do
            files:append(note_set:path_file(note_path))
        end
    end

    return files
end

return Notes
