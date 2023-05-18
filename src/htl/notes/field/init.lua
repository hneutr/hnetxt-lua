local List = require("hl.List")
local StringField = require("htl.notes.field.string")
local BoolField = require("htl.notes.field.bool")
local ListField = require("htl.notes.field.list")
local DateField = require("htl.notes.field.date")

local Fields = {}

Fields.classes = {
    DateField,
    BoolField,
    ListField,
    StringField,
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

    if List.is_listlike(fields) then
        for i, key in ipairs(fields) do
            fields[key] = {}
            fields[i] = nil
        end
    end

    if fields.date == false then
        fields.date = nil
    else
        fields.date = DateField.default
    end

    for key, args in pairs(fields) do
        fields[key] = StringField.format(key, args)
    end

    return fields
end

function Fields.set_metadata(fields, metadata)
    metadata = metadata or {}
    for key, field in pairs(fields) do
        field:set_default(metadata)

        if metadata[key] then
            fields[key]:set(metadata, metadata[key])
        end
    end

    return metadata
end


function Fields.get(args_by_key)
    local fields = {}
    for key, args in pairs(args_by_key or {}) do
        fields[key] = Fields.get_field_class(args)(key, args)
    end
    return fields
end

return Fields
