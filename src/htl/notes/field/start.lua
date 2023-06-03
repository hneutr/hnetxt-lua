local DateField = require("htl.notes.field.date")
local StartField = DateField:extend()

StartField.type = 'start'

function StartField:filter_value(value)
    value = tonumber(value)
    return value and value <= tonumber(self.today)
end

function StartField:filter(metadata, val_condition, val_type_condition)
    if self:get(metadata) == nil then
        return true
    else
        return self.super.filter(self, metadata, val_condition, val_type_condition)
    end
end

return StartField
