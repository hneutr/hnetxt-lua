local Object = require("hl.object")

local Project = require("htl.project")
local Fields = require("htl.project.notes.fields")
local Entries = require("htl.project.notes.entries")

local Registry = Object:extend()

function Registry.from_project_name(name)
    local project = Project(name)
    return Registry(project.metadata.notes, project.root)
end

function Registry.from_path(path)
    local project = Project.from_path(path)
    return Registry(project.metadata.notes, project.root)
end

-- this is to be used for:
-- - touch
-- - edit
function Registry.get_entry_set_from_path(path)
end

-- the idea is to use this for `list`
function Registry.get_entry_sets_from_path(path)
end


function Registry:new(config, root)
    self.config = Entries.format_config(config)
    self.root = root

    self.entry_sets = {}
    for key, entry_config in pairs(self.config) do
        local EntryClass = Entries.get_class(entry_config)
        self.entry_sets[key] = EntryClass(key, entry_config, self.entry_sets, self.root)
    end
end

return Registry
