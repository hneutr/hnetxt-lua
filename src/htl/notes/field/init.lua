local List = require("hl.List")

local StringField = require("htl.notes.field.string")
local BoolField = require("htl.notes.field.bool")
local ListField = require("htl.notes.field.list")
local DateField = require("htl.notes.field.date")
local StartField = require("htl.notes.field.start")
local EndField = require("htl.notes.field.end")

local Fields = {}

Fields.value_type_conditions = {
    "all",
    "expected",
    "unexpected",
}

Fields.classes = {
    StartField,
    EndField,
    DateField,
    BoolField,
    ListField,
    StringField,
}

function Fields.get_key_class(key)
    for _, class in ipairs(Fields.classes) do
        if key == class.type then
            return class
        end
    end
end

function Fields.get_args_class(args, key)
    local key_class = Fields.get_key_class(key)
    if key_class then
        return key_class
    end

    for _, class in ipairs(Fields.classes) do
        if args.type == class.type or class.is_of_type(args) then
            return class
        end
    end

    return StringField
end

function Fields.get_val_class(val, key)
    local key_class = Fields.get_key_class(key)
    if key_class then
        return key_class
    end

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
            field = Fields.get_val_class(metadata[key], key)(key)
        end

        metadata[key] = field:filter(
            metadata,
            filters[key],
            value_type_condition
        )
    end

    return metadata
end

function Fields.remove(metadata, key, val)
    if key and metadata[key] ~= nil then
        if val then
            Fields.get_val_class(metadata[key], key)(key):remove(metadata, val)
        else
            metadata[key] = nil
        end
    end

    return metadata
end

function Fields.move(metadata, source_key, source_val, target_key, target_val)
    if source_key and target_key and metadata[source_key] ~= nil then
        if source_val and target_val then
            Fields.get_val_class(metadata[source_key], source_key)(source_key):move(
                metadata,
                source_val,
                target_val
            )
        end

        if source_key ~= target_key then
            metadata[target_key] = metadata[source_key]
            metadata[source_key] = nil
        end
    end

    return metadata
end

function Fields.get(args_by_key)
    local fields = {}
    for key, args in pairs(args_by_key or {}) do
        fields[key] = Fields.get_args_class(args, key)(key, args)
    end
    return fields
end

return Fields
