local class = require("pl.class")
local List = require("hl.List")
local Path = require("hl.path")

local Fields = require("htl.notes.field")
local File = require("htl.notes.note.file")

class.FileSet()

FileSet.type = 'file'
FileSet.config_keys = {
    'subsets',
    'fields',
    'filters',
    'type',
}

function FileSet.format(set)
    set.fields = Fields.format(set.fields)
    return set
end

function FileSet:_init(path, config)
    for k, v in pairs(config or {}) do
        self[k] = v
    end

    self.path = path
end

function FileSet:files()
    return Path.iterdir(self.path, {recursive = false, dirs = false})
end

function FileSet.next_index(paths)
    local index = 0
    for _, path in ipairs(paths) do
        local stem = Path.stem(path)

        local is_date = #stem == 8 and stem:startswith("20")

        if not is_date then
            local number = tonumber(stem)
        
            if number and number > index then
                index = number
            end
        end
    end
    return index + 1
end

function FileSet:get_path_to_touch(path, args)
    args = Dict(args)

    if args.date then
        stem = os.date("%Y%m%d")
    elseif args.next then
        stem = self.next_index(self:files(path))
    else
        stem = Path.stem(path)
        path = Path.parent(path)
    end

    return Path.joinpath(path, stem .. ".md")
end

function FileSet:path_config(path)
    return self
end

function FileSet:path_file(path)
    local config = self:path_config(path)
    return File(path, config.fields, config.filters)
end

function FileSet:touch(path, args, metadata)
    path = self:get_path_to_touch(path, args)

    if path and not Path.exists(path) then
        self:path_file(path):touch(metadata)
    end

    return path
end

return FileSet
