local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")
local Path = require("hl.path")
local Yaml = require("hl.yaml")

local Fields = require("htl.notes.field")

class.File()
File.type = 'file'

function File:_init(path, fields, filters)
    self.path = path
    self.fields = Fields.get(fields)
    self.filters = filters or {}
end

function File:write(metadata, content)
    content = content or ""
    Yaml.write_document(self.path, metadata, content)
end

function File:read()
    local metadata, content = {}, ""

    if Path.exists(self.path) then
        metadata, content = unpack(Yaml.read_document(self.path))
    end

    return {metadata, content}
end

function File:touch(metadata)
    if not Path.exists(self.path) then
        self:write(Fields.set_metadata(self.fields, metadata))
    end
end

function File:get_metadata()
    return self:read()[1]
end

function File:get_content()
    return self:read()[2]
end

function File:get_stem()
    return Path.stem(self.path)
end

function File:get_name()
    return Path.name(self.path)
end

function File:get_blurb()
    local content = self:get_content()

    local blurb = content:splitlines()[1]

    if #blurb == 0 then
        blurb = self:get_stem():gsub("-", " ")
    end

    return blurb
end

function File:get_set_path()
    return Path.parent(self.path)
end

function File:set_metadata(new_metadata)
    local metadata, content = unpack(self:read())

    metadata = Fields.set_metadata(self.fields, Dict(new_metadata, metadata))

    self:write(metadata, content)
end

function File:remove_metadata(field, value)
    local metadata, content = unpack(self:read())

    metadata = Fields.remove(metadata, field, value)
    self:write(metadata, content)
end

function File:move_metadata(source_field, source_value, target_field, target_value)
    local metadata, content = unpack(self:read())

    metadata = Fields.move(metadata, source_field, source_value, target_field, target_value)
    self:write(metadata, content)
end

function File:flatten_metadata(field)
    local metadata, content = unpack(self:read())

    if metadata[field] and type(metadata[field]) == 'table' then
        local vals = List()
        for _, val in ipairs(metadata[field]) do
            vals:append(tostring(val))
        end

        metadata[field] = string.join(", ", vals)
        self:write(metadata, content)
    end
end

function File:get_filtered_metadata(value_type_condition)
    return Fields.filter(self:get_metadata(), self.fields, self.filters, value_type_condition)
end

function File:get_filtered_metadata_by_value_type_condition(filters, apply_config_filters)
    local metadata_by_value_type_condition = {}
    for _, value_type_condition in ipairs(Fields.value_type_conditions) do
        metadata_by_value_type_condition[value_type_condition] = self:get_filtered_metadata(
            filters,
            apply_config_filters,
            value_type_condition
        )
    end

    return metadata_by_value_type_condition
end

function File:meets_filters(value_type_condition)
    local metadata = self:get_filtered_metadata(value_type_condition)

    local required_fields = List.from(self.filters, Dict.keys(self.filters))

    for _, required_field in ipairs(required_fields) do
        local val = metadata[required_field]
        if val == nil then
            return false
        elseif type(val) == 'table' and #val == 0 then
            return false
        end
    end

    return true
end

function File:get_list_info(value_type_condition, relative_to)
    if not self:meets_filters(value_type_condition) then
        return nil
    end

    return {
        path = Path.relative_to(self.path, relative_to),
        stem = self:get_stem(),
        name = self:get_name(),
        blurb = self:get_blurb(),
        set_path = Path.relative_to(self:get_set_path(), relative_to),
        metadata = self:get_filtered_metadata(value_type_condition),
        metadata_by_value_type_condition = self:get_filtered_metadata_by_value_type_condition(),
    }
end

return File
