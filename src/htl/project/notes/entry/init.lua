table = require('hl.table')
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Object = require("hl.object")

local Fields = require("htl.project.notes.fields")

local Entry = Object:extend()
Entry.type = 'entry'
Entry.iterdir_args = {recursive = false, dirs = false}

function Entry.format(entries, key, entry)
    return entries
end

function Entry:new(key, config, entry_sets, root)
    for k, v in pairs(config or {}) do
        self[k] = v
    end

    self.key = key
    self.entry_sets = entry_sets
    self.root = root

    self.fields = Fields.get(self.fields)

    self.entry_set_path = Path.joinpath(self.root, self.key)
end

function Entry:move(source, target)
    Path.rename(source, target)
end

function Entry:remove(path)
    Path.unlink(path)
end

function Entry:paths()
    return Path.iterdir(self.entry_set_path, self.iterdir_args)
end

function Entry:get_metadata(path)
    return Yaml.read_document(path)[1] or {}
end

function Entry:path(path)
    return Path.joinpath(self.entry_set_path, Path.stem(path) .. ".md")
end

function Entry:new_entry(path, metadata)
    path = self:path(path, metadata)

    if not path then
        return
    end

    metadata = metadata or {}
    for key, field in pairs(self.fields) do
        if metadata[key] then
            field:set(metadata, metadata[key])
        end

        field:set_default(metadata)
    end

    Yaml.write_document(path, metadata, {""})
    return path
end

function Entry:set_metadata(path, map)
    local metadata, content = {}, {}
    if Path.exists(path) then
        metadata, content = unpack(Yaml.read_document(path))
    end

    for key, value in pairs(map) do
        self.fields[key]:set(metadata, value)
    end

    Yaml.write_document(path, metadata, content)
end

return Entry
