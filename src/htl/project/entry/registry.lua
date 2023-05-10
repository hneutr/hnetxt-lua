local Object = require("hl.object")

local Project = require("htl.project")
local Fields = require("htl.project.entry.fields")
local Entries = require("htl.project.entry.entries")

local Registry = Object:extend()

function Registry.format_entries()

function Registry.format(raw)
    raw = raw or {}
    local fields = Fields.format(raw.fields)
    -- local 

    -- config.entries = config.entries or {}

    -- if table.is_list(config.entries) then
    --     for i, entry in ipairs(config.entries) do
    --         config.entries[entry] = {}
    --         config.entries[i] = nil
    --     end
    -- end

    -- for entry, subconfig in pairs(config.entries) do
    --     subconfig.type = subconfig.type or 'entry'
    --     subconfig = Config.format_all_config_entries(subconfig)
    -- end

    -- return config
end

function Registry.get(args_by_key)
    -- local fields = {}
    -- for key, args in pairs(Fields.format(args_by_key)) do
    --     args = Field.format(key, args)
    --     fields[field] = Fields.get_field_class(args)(key, args)
    -- end
    -- return fields
end

function Registry.from_path(path)
    local project = Project.from_path(path)
    return Registry(project.metadata.entries)
end


function Registry:new(config, root)
    self.config = Entries.format(config)
    self.entries = {}
--     self.project_root = Project.root_from_path(project_path)
--     self.project_entry_sets = EntryConfigs.Config.from_project_path(self.project_root)
--     self.entry_sets = {}
--     for entry, config in pairs(self.project_entry_sets) do
--         self.entry_sets[entry] = self:get_entry_set(entry, config)
--     end
end

return Registry


