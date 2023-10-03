local DateField = require("htl.notes.field.date")
local EndField = DateField:extend()

EndField.type = 'end'
EndField.default = ''

function EndField:new(key, args)
    DateField.new(self, key, args)
    self.default = ''
end

function EndField:filter_value(value)
    if value == "" then
        return true
    end

    value = tonumber(value)
    return value and tonumber(self.today) <= value
end

function EndField:filter(metadata, val_condition, val_type_condition)
    if self:get(metadata) == nil then
        return true
    else
        return self.super.filter(self, metadata, val_condition, val_type_condition)
    end
end

return EndField
