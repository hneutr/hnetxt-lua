local Object = require("hl.object")

local Project = require("htl.project")
local Fields = require("htl.notes.field")
local Sets = require("htl.notes.set")

local Notes = Object:extend()

function Notes.from_path(path)
    local project = Project.from_path(path)
    return Registry(project.metadata.notes, project.root)
end

-- this is to be used for:
-- - touch
-- - edit
function Notes.get_set_from_path(path)
end

-- the idea is to use this for `list`
function Notes.get_sets_from_path(path)
end


function Notes:new(config, root)
    self.sets = {}
    for key, set_config in pairs(Sets.format_config(config)) do
        key = Path.joinpath(root, key)
        self.sets[key] = Sets.get_class(set_config)(key, entry_config)
    end
end

return Registry
