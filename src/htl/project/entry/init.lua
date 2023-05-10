table = require('hl.table')

local Fields = require("htl.project.entry.fields")

local Object = require("hl.object")

local Entry = Object:extend()
Entry.type = 'entry'
Entry.keys = {
    "fields",
    "type",
}

function Entry:new(name, registry, args, parent)
    self.name = name
    self.registry = registry
    self.args = args or {}
    self.parent = parent or {}
    self.fields = table.default(Field.format(args.fields), self.parent.fields)

    -- self.entries = self.config.entries
end

function Entry.move_entry_into_dir(entry, dir)
    if Path.is_relative_to(entry, "..") then
        return Path.relative_to(entry, "..")
    end

    if entry ~= dir and not Path.is_relative_to(entry, dir) then
        entry = Path.joinpath(dir, entry)
    end

    return entry
end

function Entry:move_into_dir(dir)
    self.name = Entry.move_entry_into_dir(self.name, dir)
end

-- EntrySet.iterdir_args = {recursive = false, dirs = false}

-- function EntrySet:new(name, config, set_config)
--     self.name = name
--     self.set_config = set_config
--     for k, v in pairs(config) do
--         self[k] = v
--     end
--     self.fields = FieldConfig.get_fields(self.fields)
--     self.path = Path.joinpath(self.set_config.project_root, self.name)
--     self.items = self:find_items()
-- end

-- function EntrySet:find_items()
--     local items = {}
--     for _, path in ipairs(Path.iterdir(self.path, self.iterdir_args)) do
--         table.insert(items, path)
--     end

--     table.sort(items)
--     return items
-- end

-- function EntrySet:get_metadata(path)
--     return Yaml.read_document(path)[1]
-- end

-- function EntrySet:new_entry(path, metadata)
--     metadata = metadata or {}
--     for key, field in pairs(self.fields) do
--         if not metadata[key] then
--             metadata[key] = field.default
--         end
--     end

--     return Yaml.write_document(path, metadata, {""})
-- end

-- function EntrySet:set_metadata(path, map)
--     local metadata, content = unpack(Yaml.read_document(path))

--     for key, value in pairs(map) do
--         metadata[key] = value
--     end

--     Yaml.write_document(path, metadata, content)
-- end

return Entry
