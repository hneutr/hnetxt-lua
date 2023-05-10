table = require('hl.table')

local Object = require("hl.object")

local Field = Object:extend()
Field.type = 'field'

function Field:new(key, args)
    args = table.default(args, {values = {}})
    self.key = key
    self.default = args.default
    self.values = args.values
end

function Field:in_values(value)
    return self.values == nil or #self.values == 0 or table.list_contains(self.values, value)
end

function Field:get(metadata)
    return metadata[self.key]
end

function Field:set(metadata, value)
    if self:in_values(value) then
        metadata[self.key] = value
    end
end

function Field:set_default(metadata)
    if not self:get(metadata) then
        self:set(metadata, self.default)
    end
end

function Field.format(key, raw)
    local args = {key = key}

    if table.is_list(raw) then
        args.values = raw
    elseif type(raw) == 'table' then
        args = table.default(args, raw)
    else
        args.default = raw
    end

    return args
end

function Field.is_of_type()
    return true
end

return Field
