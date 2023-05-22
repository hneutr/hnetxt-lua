local List = require("hl.PList")
local Set = require("pl.Set")
local StringField = require("htl.notes.field.string")

local ListField = StringField:extend()
ListField.type = 'list'
ListField.default = {}

function ListField:new(key, args)
    self.super.new(self, key, args)
    self.default = self:clean(self.default)
end

function ListField:clean(value)
    value = value or {}

    if type(value) ~= 'table' then
        value = {value}
    end

    local _value = {}
    for _, v in ipairs(value) do
        if self:in_values(v) then
            table.insert(_value, v)
        end
    end

    return _value
end

function ListField:set(metadata, value)
    metadata[self.key] = self:clean(value)
end

function ListField:set_default(metadata)
    self:set(metadata, self:get(metadata) or self.default)
end

function ListField:remove(metadata, to_remove)
    local vals = List()
    for _, val in ipairs(self:get(metadata)) do
        if val ~= to_remove then
            vals:append(val)
        end
    end

    self:set(metadata, vals)
end

function ListField:move(metadata, source, target)
    local vals = List()
    for _, val in ipairs(self:get(metadata)) do
        if val == source then
            val = target
        end

        vals:append(val)
    end

    self:set(metadata, vals)
end

function ListField.is_of_type(args)
    return List.is_listlike(args.default)
end

function ListField.val_is_of_type(val)
    return List.is_listlike(val)
end

function ListField:filter_value(val, condition)
    condition = List.as_list(condition)
    return #condition == 0 or condition:contains(val)
end

function ListField:filter(metadata, val_condition, val_type_condition)
    local vals = List()
    for _, val in ipairs(self:get(metadata)) do
        if self:filter_value(val, val_condition) and self:filter_value_type(val, val_type_condition) then
            vals:append(val)
        end
    end

    return vals
end

return ListField
