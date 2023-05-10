local Field = require("htl.project.entry.field")
local DateField = Field:extend()

DateField.type = 'date'
DateField.default = os.date('%Y%m%d')

function DateField:new(key, args)
    self.super.new(self, key, args)
    self.values = nil
    self.default = DateField.default
end

function DateField.is_of_type(args)
    return args.key == DateField.type
end

return DateField
