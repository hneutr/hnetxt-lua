local List = require("hl.List")
local Dict = require("hl.Dict")

local Object = require("hl.object")

local StringField = Object:extend()
StringField.type = 'string'

function StringField:new(key, args)
    args = Dict.update(args, {values = {}})
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
        args = Dict.update(args, raw)
    else
        args.default = raw
    end

    return args
end

function StringField.is_of_type()
    return true
end

function StringField:filter_value(value, condition)
    return condition == nil or value == condition
end

function StringField:filter_value_type(value, condition)
    if condition == nil then
        return true
    end

    local in_values = self:in_values(value)

    if condition == 'expected' then
        return in_values
    elseif condition == 'unexpected' then
        return not in_values
    end
end

function StringField:filter(metadata, value_condition, value_type_condition)
    local value = self:get(metadata)
    return self:filter_value(value, value_condition) and self:filter_value_type(value, value_type_condition)
end

return StringField
