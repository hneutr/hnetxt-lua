local List = require("hl.List")
local Dict = require("hl.Dict")

local Object = require("hl.object")

local StringField = Object:extend()
StringField.type = 'string'

function StringField:new(key, args)
    args = Dict(args, {values = {}})
    self.key = key
    self.default = args.default
    self.values = args.values
end

function StringField:in_values(value)
    return self.values == nil or #self.values == 0 or List.contains(self.values, value)
end

function StringField:get(metadata)
    return metadata[self.key]
end

function StringField:set(metadata, value)
    if self:in_values(value) then
        metadata[self.key] = value
    end
end

function StringField:set_default(metadata)
    if self:get(metadata) == nil then
        self:set(metadata, self.default)
    end
end

function StringField.format(key, raw)
    local args = {}

    if List.is_listlike(raw) then
        args.values = raw
    elseif type(raw) == 'table' then
        args = Dict(args, raw)
    else
        args.default = raw
    end

    return args
end

function StringField.is_of_type()
    return true
end

return StringField
