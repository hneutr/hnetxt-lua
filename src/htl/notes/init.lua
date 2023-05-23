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

    local sets = Dict()
    for set_key, config in pairs(configs) do
        set_path = Path.joinpath(project.root, set_key)
        sets[set_path] = Sets.get_class(config)(set_path, config)
    end

    return sets
end

function Notes.path_set(path)
    local sets = Notes.sets(path)
    sets:filterk(function(k) return k == path or Path.is_relative_to(path, k) end)
    local set_paths = sets:keys():sort(function(a, b) return #a > #b end)
    return sets[set_paths[1]]
end

function Notes.path_sets(path)
    local sets = Notes.sets(path)
    sets:filterk(function(k) return k == path or Path.is_relative_to(k, path) end)

    if #sets:keys() == 0 then
        local set = Notes.path_set(path)
        sets[set.path] = set
    end

    return sets
end

function Notes.path_files(path)
    local files = List()
    Notes.path_sets(path):foreachv(function(set)
        List(set:files(path)):foreach(function(p)
            files:append(set:path_file(p))
        end)
    end)

    return files
end

return Notes
