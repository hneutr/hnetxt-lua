local Object = require("hl.object")

local Field = require("htl.project.entry.field")
local BoolField = require("htl.project.entry.field.bool")
local ListField = require("htl.project.entry.field.list")
local DateField = require("htl.project.entry.field.date")

local Fields = {}

Fields.classes = {
    DateField,
    BoolField,
    ListField,
    Field,
}

function Fields.get_field_class(args)
    for _, class in ipairs(Fields.classes) do
        if args.type == class.type or class.is_of_type(args) then
            return class
        end
    end

    return Field
end

function Fields.format(fields)
    fields = fields or {}

    if table.is_list(fields) then
        for i, key in ipairs(fields) do
            fields[key] = {}
            fields[i] = nil
        end
    end

    if fields.date == false then
        fields.date = nil
    else
        fields.date = {}
    end

    for key, args in pairs(fields) do
        fields[key] = Field.format(key, args)
    end

    return fields
end

function Fields.get(args_by_key)
    local fields = {}
    for key, args in pairs(args_by_key) do
        fields[field] = Fields.get_field_class(args)(key, args)
    end
    return fields
end

return Fields
