local Field = require("htl.project.entry.field")

local ListField = Field:extend()
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

function ListField.is_of_type(args)
    return table.is_list(args.default)
end

return ListField
