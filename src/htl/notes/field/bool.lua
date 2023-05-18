local StringField = require("htl.notes.field.string")

local BoolField = StringField:extend()
BoolField.type = 'bool'
BoolField.values = {true, false}

function BoolField:new(key, args)
    self.super.new(self, key, args)
    self.values = BoolField.values
end

function BoolField.is_of_type(args)
    return type(args.default) == 'boolean'
end


return BoolField
