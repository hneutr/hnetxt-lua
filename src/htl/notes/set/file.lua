local List = require("hl.List")
local Path = require("hl.path")

local Fields = require("htl.notes.field")
local File = require("htl.notes.file")

require("pl.class").FileSet()

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

-- TODO: filter metadata here
-- TODO: also will need to figure out how to cue to TopicSet that we want ALL notes when listing
-- fields
function FileSet:list(path)
    local items = List()
    local set_path = Path.relative_to(self.path, path)

    for _, item_path in ipairs(self:files()) do
        local file = self:path_file(item_path)
        local metadata, content = unpack(file:read())

        content = content:splitlines()
        local blurb = content[1]

        if #blurb == 0 then
            blurb = Path.stem(path):gsub("-", " ")
        end

        item_path = Path.relative_to(item_path, path):removeprefix("/")

        items:append({
            path = item_path,
            clean_path = Path.with_suffix(item_path, ''):gsub('-', " "):removeprefix("/"),
            set_path = set_path,
            metadata = metadata,
            blurb = blurb,
        })
    end

    return items
end

return FileSet
