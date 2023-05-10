local Object = require("hl.object")

local Project = require("htl.project")
local Fields = require("htl.project.notes.fields")
local Entries = require("htl.project.notes.entries")

local Registry = Object:extend()

function Registry.from_path(path)
    local project = Project.from_path(path)
    return Registry(project.metadata.entries, project.root)
end

function Registry:new(config, root)
    self.config = Entries.format(config)
    self.root = root

    self.entry_sets = {}
    for key, entry_config in pairs(self.config.entries) do
        local EntryClass = Entries.get_class(entry_config)
        self.entry_sets[key] = EntryClass(key, entry_config, self.entry_sets, self.root)
    end
end

return Registry
