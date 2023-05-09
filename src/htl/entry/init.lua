--[[
Current process:
1. parse each entry's config
2. take those configs and make EntrySets

this is annoying because I have separated code for parsing an EntrySet config and for the EntrySet

better way to do it:
1. make a EntryConfig object
2. parse each each entry's config and it the EntryConfig object. 
    - have it add itself to the EntryConfig object
    - have it add any subentries to the EntryConfig object too

also TODO:
- have set_metadata use the field type definition to add/remove items from lists

--]]

string = require("hl.string")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Object = require("hl.object")

local Project = require("htl.project")

local FieldConfig = require("htl.entry.field").FieldConfig
local EntryConfigs = require("htl.entry.config")
local EntryConfig = EntryConfigs.EntryConfig
local PromptEntryConfig = EntryConfigs.PromptEntryConfig
local ResponseEntryConfig = EntryConfigs.ResponseEntryConfig
local ListEntryConfig = EntryConfigs.ListEntryConfig

--------------------------------------------------------------------------------
--                                  Entries                                   --
--------------------------------------------------------------------------------
local EntrySet = Object:extend()
EntrySet.iterdir_args = {recursive = false, dirs = false}

function EntrySet:new(name, config, set_config)
    self.name = name
    self.set_config = set_config
    for k, v in pairs(config) do
        self[k] = v
    end
    self.fields = FieldConfig.get_fields(self.fields)
    self.path = Path.joinpath(self.set_config.project_root, self.name)
    self.items = self:find_items()
end

function EntrySet:find_items()
    local items = {}
    for _, path in ipairs(Path.iterdir(self.path, self.iterdir_args)) do
        table.insert(items, path)
    end

    table.sort(items)
    return items
end

function EntrySet:get_metadata(path)
    return Yaml.read_document(path)[1]
end

function EntrySet:new_entry(path, metadata)
    metadata = metadata or {}
    for key, field in pairs(self.fields) do
        if not metadata[key] then
            metadata[key] = field.default
        end
    end

    return Yaml.write_document(path, metadata, {""})
end

function EntrySet:set_metadata(path, map)
    local metadata, content = unpack(Yaml.read_document(path))

    for key, value in pairs(map) do
        metadata[key] = value
    end

    Yaml.write_document(path, metadata, content)
end

--------------------------------------------------------------------------------
--                                 PromptSet                                  --
--------------------------------------------------------------------------------
local PromptSet = EntrySet:extend()
function PromptSet:response_sets()
    return self.set_config.entry_sets[self.response_dir]
end

function PromptSet:reopen(path)
    self:set_metadata(path, {open = true})
end

function PromptSet:close(path)
    self:set_metadata(path, {open = false})
end

function PromptSet:responses(path)
    path = Path.joinpath(self.set_config.project_root, self.response_dir, Path.stem(path))

    local responses = {}
    for _, response in ipairs(self:response_sets().items) do
        if Path.parent(response) == path then
            table.insert(responses, response)
        end
    end

    return responses
end

function PromptSet:response(path, all)
    local responses = self:responses(path)
    local pinned_responses = {}

    for _, response in ipairs(responses) do
        local metadata = self:get_metadata(response)
        if metadata.pinned then
            table.insert(pinned_responses, response)
        end
    end

    if #pinned_responses == 0 or all then
        return responses
    end

    return pinned_responses
end

function PromptSet:respond(path)
    local path = Path.joinpath(
        self.set_config.project_root,
        self.response_dir,
        Path.stem(path),
        os.date("%Y%m%d") .. ".md"
    )

    self.set_config.entry_sets[self.response_dir]:new_entry(path)
    return path
end

--------------------------------------------------------------------------------
--                                ResponseSet                                 --
--------------------------------------------------------------------------------
local ResponseSet = EntrySet:extend()
ResponseSet.iterdir_args = {recursive = true, dirs = false}

function ResponseSet:get_prompt_set()
    return self.set_config.entry_sets[self.prompt_dir]
end

function ResponseSet:path(path, date)
    date = date or os.date("%Y%m%d")

    return Path.joinpath(
        self.set_config.project_root,
        self.name,
        Path.stem(path),
        date .. ".md"
    )
end

--------------------------------------------------------------------------------
--                                  ListSet                                   --
--------------------------------------------------------------------------------
local ListSet = EntrySet:extend()
ListSet.iterdir_args = {recursive = true, dirs = false}

--------------------------------------------------------------------------------
--                                   Entry                                    --
--------------------------------------------------------------------------------
-- function Entry:new(name, args)
-- end

-- function Entry:path(args)
-- end

-- function Entry:set(args)
-- end

-- function Entry:flip(args)
-- end

-- function PromptEntry:respond(args)
-- end

-- function ResponseEntry:pin(args)
-- end

-- function ResponseEntry:unpin(args)
-- end

-- function ResponseEntry:paths(args)
-- end

-- function ListEntry:paths(args)
-- end

------------------------------------[ misc ]------------------------------------
local SetConfig = Object:extend()
SetConfig.entry_type_to_entry_set_class = {
    [EntryConfig.type] = EntrySet,
    [PromptEntryConfig.type] = PromptSet,
    [ResponseEntryConfig.type] = ResponseSet,
    [ListEntryConfig.type] = ListSet,
}

function SetConfig:get_entry_set(name, config)
    return self.entry_type_to_entry_set_class[config.type](name, config, self)
end

function SetConfig:new(project_path)
    self.project_root = Project.root_from_path(project_path)
    self.project_entry_sets = EntryConfigs.Config.from_project_path(self.project_root)
    self.entry_sets = {}
    for entry, config in pairs(self.project_entry_sets) do
        self.entry_sets[entry] = self:get_entry_set(entry, config)
    end
end

-- function Entry:new(path)
--     self.path = path
--     self.metadata, self.text = unpack(Yaml.read_document(self.path))
-- end

-- function Entry:write()
--     Yaml.write(self.path, self.metadata, self.text)
-- end

-- function Entry:set_metadata(key, value)
-- end

return {
    EntrySet = EntrySet,
    PromptSet = PromptSet,
    ResponseSet = ResponseSet,
    ListSet = ListSet,
    SetConfig = SetConfig
}
