local List = require("hl.List")

local StringField = require("htl.notes.field.string")
local BoolField = require("htl.notes.field.bool")
local ListField = require("htl.notes.field.list")
local DateField = require("htl.notes.field.date")

local Fields = {}

Fields.value_type_conditions = {
    "all",
    "expected",
    "unexpected",
}

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

    return StringField
end

function Fields.get_value_field_class(val)
    for _, class in ipairs(Fields.classes) do
        if class.val_is_of_type(val) then
            return class
        end
    end

    return StringField
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

function Fields.filter(metadata, fields, filters, value_type_condition)
    metadata = Dict.update(metadata)
    for key, value in pairs(filters) do
        local field = fields[key]

        if not field then
            field = Fields.get_value_field_class(metadata[key])(key)
        end

        metadata[key] = field:filter(
            metadata,
            filters[key],
            value_type_condition
        )
    end

    return metadata
end

function Fields.remove(metadata, field, value)
    if field and metadata[field] ~= nil then
        if value then
            Fields.get_value_field_class(metadata[field])(field):remove(metadata, value)
        else
            metadata[field] = nil
        end
    end

    return metadata
end

function Fields.move(metadata, source_field, source_value, target_field, target_value)
    if source_field and target_field and metadata[source_field] ~= nil then
        if source_value and target_value then
            Fields.get_value_field_class(metadata[source_field])(source_field):move(
                metadata,
                source_value,
                target_value
            )
        end

        if source_field ~= target_field then
            metadata[target_field] = metadata[source_field]
            metadata[source_field] = nil
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
