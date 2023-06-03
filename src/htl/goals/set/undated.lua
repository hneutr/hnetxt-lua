string = require("hl.string")
local class = require("pl.class")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Fields = require("htl.notes.field")
local YearSet = require("htl.goals.set.year")
local Goal = require("htl.goals.goal")

class.UndatedSet(YearSet)

UndatedSet.type = 'undated'

function UndatedSet:get_metadata(path)
    return Yaml.read_document(path)[1]
end

function UndatedSet:get_content(path)
    return Yaml.read_document(path)[2]
end

function UndatedSet:is_current(path)
    local metadata = Fields.filter(self:get_metadata(path), {}, {start = true, ["end"] = true})
    return metadata['start'] and metadata['end']
end

function UndatedSet:is_instance(path)
    return true
end

function UndatedSet:is_open(path)
    if Path.exists(path) then
        return Goal.any_open(self:get_content():splitlines())
    end
end

function UndatedSet:touch(path)
    if not Path.exists(path) then
        local metadata = {
            date = tonumber(os.date("%Y%m%d")),
            start = tonumber(os.date("%Y%m%d")),
            ["end"] = "",
        }
        Yaml.write_document(path, metadata, Goal.open_sigil .. " ")
    end
end

function UndatedSet:get_current(dir)
    return nil
end

return UndatedSet
