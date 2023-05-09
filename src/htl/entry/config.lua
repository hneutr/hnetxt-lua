--[[
entries:
    fields: fields present in all entries in `entries`
        date:
            - values: [true, false]
                - true:
                    - allow sorting by date
                    - default entry.date to today on entry creation
            | default: true
        FIELD:
            type: how to parse the field
                | values: [string, list, bool]
                | default: string
            values: values to allow in the field
                | default: nil
            default: value if entry.FIELD = nil
                | default: nil
    entries:
        ENTRY:
            fields:
            entries:
            type: [entry, prompt, list]
                | default: entry
            | if TYPE.type == prompt:
            response_dir: default: TYPE
            response_entry: default: responses

--]]

table = require('hl.table')
string = require('hl.string')
local Path = require("hl.path")
local Object = require("hl.object")

local Project = require("htl.project")
local FieldConfig = require("htl.entry.field").FieldConfig

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                EntryConfig                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local EntryConfig = Object:extend()
EntryConfig.type = 'entry'
EntryConfig.keys = {
    "fields",
    "type",
}

function EntryConfig:new(name, config, parent_fields)
    self.name = name
    self.config = table.default(config, {
        fields = parent_fields or {},
        entries = {},
    })

    self.fields = FieldConfig.format(self.config.fields)
    self.entries = self.config.entries
end

function EntryConfig:get()
    local config = {}
    for _, key in ipairs(self.keys) do
        config[key] = self[key]
    end
    return config
end

function EntryConfig.move_entry_into_dir(entry, dir)
    if Path.is_relative_to(entry, "..") then
        return Path.relative_to(entry, "..")
    end

    if entry ~= dir and not Path.is_relative_to(entry, dir) then
        entry = Path.joinpath(dir, entry)
    end

    return entry
end

function EntryConfig:move_into_dir(dir)
    self.name = EntryConfig.move_entry_into_dir(self.name, dir)
end

--------------------------------------------------------------------------------
--                            ResponseEntryConfig                             --
--------------------------------------------------------------------------------
local ResponseEntryConfig = EntryConfig:extend()
ResponseEntryConfig.type = 'response'
ResponseEntryConfig.response_entry = 'responses'
ResponseEntryConfig.keys = {
    "fields",
    "type",
    "prompt_dir",
}

function ResponseEntryConfig:new(name, config, parent_fields)
    config = table.default(config, {fields = {pinned = false, date = {type = "date"}}})
    self.super.new(self, name, config, parent_fields)

    self.fields = {pinned = self.fields.pinned, date = self.fields.date}

    self.prompt_dir = self.config.prompt_dir
end

function ResponseEntryConfig.get_entry_config(prompt_dir)
    return {
        type = 'response',
        prompt_dir = prompt_dir,
        entries = {},
        fields = {pinned = false, date = {type = "date"}},
    }
end

function ResponseEntryConfig:move_into_dir(dir)
    self.name = EntryConfig.move_entry_into_dir(self.name, dir)
    self.prompt_dir = EntryConfig.move_entry_into_dir(self.prompt_dir, dir)
end

--------------------------------------------------------------------------------
--                            PromptEntryConfig                             --
--------------------------------------------------------------------------------
local PromptEntryConfig = EntryConfig:extend()
PromptEntryConfig.type = 'prompt'
PromptEntryConfig.response_entry = 'responses'
PromptEntryConfig.keys = {
    "fields",
    "type",
    "response_dir",
}

function PromptEntryConfig:new(name, config, parent_fields)
    config = table.default(config, {
        fields = {open = true},
        response_entry = ResponseEntryConfig.response_entry,
        response_dir = name,
    })
    self.super.new(self, name, config, parent_fields)

    self.response_dir = Path.joinpath(self.config.response_dir, self.config.response_entry)

    self.entries = self.entries or {}
    self.entries[self.response_dir] = ResponseEntryConfig.get_entry_config(self.name)
end

function PromptEntryConfig:move_into_dir(dir)
    self.name = EntryConfig.move_entry_into_dir(self.name, dir)
    self.response_dir = EntryConfig.move_entry_into_dir(self.response_dir, dir)
end

--------------------------------------------------------------------------------
--                              ListEntryConfig                               --
--------------------------------------------------------------------------------
local ListEntryConfig = EntryConfig:extend()
ListEntryConfig.type = 'list'

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Config                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Config = Object:extend()
Config.entry_type_to_entry_class = {
    [EntryConfig.type] = EntryConfig,
    [PromptEntryConfig.type] = PromptEntryConfig,
    [ResponseEntryConfig.type] = ResponseEntryConfig,
    [ListEntryConfig.type] = ListEntryConfig,
}

function Config.format_all_config_entries(config)
    config.entries = config.entries or {}

    if table.is_list(config.entries) then
        for i, entry in ipairs(config.entries) do
            config.entries[entry] = {}
            config.entries[i] = nil
        end
    end

    for entry, subconfig in pairs(config.entries) do
        subconfig.type = subconfig.type or 'entry'
        subconfig = Config.format_all_config_entries(subconfig)
    end

    return config
end

function Config.get_project_entries(project_config)
    project_config = Config.format_all_config_entries(project_config or {})

    local entries = {}
    for name, config in pairs(project_config.entries) do
        for k, v in pairs(Config.add_entries(name, config, project_config.fields)) do
            entries[k] = v
        end
    end

    return Config.thin_entries(entries)
end

function Config.add_entries(name, config, parent_fields)
    local entry = Config.get_entry(name, config, parent_fields)
    local entries = {[name] = entry}

    for subname, subconfig in pairs(entry.entries or {}) do
        local subentries = Config.add_entries(subname, subconfig, entry.fields)
        for k, subentry in pairs(subentries) do
            subentry:move_into_dir(name)
            entries[subentry.name] = subentry
        end
    end

    return entries
end

function Config.thin_entries(entries)
    local thin_entries = {}
    for _, entry in pairs(entries) do
        thin_entries[entry.name] = entry:get()
    end
    return thin_entries
end

function Config.get_entry(name, config, parent_fields)
    return Config.entry_type_to_entry_class[config.type](name, config, parent_fields)
end

function Config.from_project_path(path)
    local project = Project.from_path(path)
    return Config.get_project_entries(project.metadata.entries)
end


return {
    EntryConfig = EntryConfig,
    PromptEntryConfig = PromptEntryConfig,
    ResponseEntryConfig = ResponseEntryConfig,
    ListEntryConfig = ListEntryConfig,
    Config = Config,
}
