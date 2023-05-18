local StringField = require("htl.notes.field.string")
local DateField = StringField:extend()

DateField.type = 'date'
DateField.default = os.date('%Y%m%d')

function DateField:new(key, args)
    self.super.new(self, key, args)
    self.values = nil
    self.default = DateField.default
end

function DateField.is_of_type(args)
    return args.default == DateField.default
end

function DateField.default_config()
    return {type = DateField.type}
end

return DateField
