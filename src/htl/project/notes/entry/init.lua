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

function Entry:read(path)
    local metadata, content = {}, {""}

    if Path.exists(path) then
        metadata, content = unpack(Yaml.read_document(path))
    end

    return {metadata, content}
end

function Entry:write(path, metadata, content)
    Yaml.write_document(path, metadata, content)
end

function Entry:new_entry(path, metadata)
    self:write(path, Fields.set_metadata(self.fields, metadata), {""})
end

function Entry:get_metadata(path)
    return self:read(path)[1]
end

function Entry:set_metadata(path, new_metadata)
    local metadata, content = unpack(self:read(path))

    metadata = Fields.set_metadata(self.fields, table.default(new_metadata, metadata))
    self:write(path, metadata, content)
end

return Entry
