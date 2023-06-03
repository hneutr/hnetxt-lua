local StringField = require("htl.notes.field.string")
local DateField = StringField:extend()

DateField.type = 'date'
DateField.today = os.date('%Y%m%d')
DateField.default = DateField.today

function DateField:new(key, args)
    DateField.super.new(self, key, args)
    self.values = nil
    self.default = self.today
end

function DateField.is_of_type(args)
    return args.default == DateField.today
end

function DateField.val_is_of_type(val)
    return tonumber(val) and #tostring(val) == 8
end

function DateField:set(metadata, value)
    DateField.super.set(self, metadata, tonumber(value))
end

return DateField
