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

function StringField:remove(metadata, to_remove)
    if self:get(metadata) == to_remove then
        metadata[self.key] = nil
    end
end

function StringField:move(metadata, source, target)
    if self:get(metadata) == source then
        metadata[self.key] = target
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

function StringField.val_is_of_type()
    return true
end

function StringField:filter_value(value, condition)
    return condition == nil or value == condition
end

function StringField:filter_value_type(value, condition)
    if condition == nil or condition == 'all' then
        return true
    end

    local in_values = self:in_values(value)

    if condition == 'expected' then
        return in_values
    elseif condition == 'unexpected' then
        return not in_values
    end
end

function StringField:filter(metadata, val_condition, val_type_condition)
    local val = self:get(metadata)
    if self:filter_value(val, val_condition) and self:filter_value_type(val, val_type_condition) then
        return val
    end

    return nil
end

return StringField
