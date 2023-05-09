table = require('hl.table')

local Object = require("hl.object")

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   Field                                    --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Field = Object:extend()
Field.type = 'field'

function Field:new(key, config)
    self.key = key
    self.default = config.default
    self.values = config.values
end

function Field.format(config)
    local _type, default, values

    if type(config) == 'boolean' then
        default = config
    elseif type(config) == 'string' then
        default = config
    elseif table.is_list(config) then
        values = config
    elseif type(config) == 'table' then
        _type = config.type
        default = config.default
        values = config.values
    end

    if type(default) == 'boolean' then
        _type = 'bool'
    elseif table.is_list(default) then
        _type = 'list'
    end

    if _type == nil then
        _type = 'field'
    end

    return {type = _type, default = default, values = values}
end

--------------------------------------------------------------------------------
--                                 BoolField                                  --
--------------------------------------------------------------------------------
local BoolField = Field:extend()
BoolField.type = 'bool'
BoolField.values = {true, false}

function BoolField:new(key, config)
    config.values = nil
    self.super.new(self, key, config)
end

--------------------------------------------------------------------------------
--                                 ListField                                  --
--------------------------------------------------------------------------------
local ListField = Field:extend()
ListField.type = 'list'

--------------------------------------------------------------------------------
--                                 DateField                                  --
--------------------------------------------------------------------------------
local DateField = Field:extend()
DateField.type = 'date'
DateField.default = os.date('%Y%m%d')

function DateField:new(key, config)
    config.default = nil
    config.values = nil
    self.super.new(self, key, config)
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                FieldConfig                                 --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local FieldConfig = Object:extend()
FieldConfig.field_type_to_field_class = {
    [BoolField.type] = BoolField,
    [ListField.type] = ListField,
    [DateField.type] = DateField,
    [Field.type] = Field,
}

function FieldConfig.get_fields(field_configs)
    local fields = {}
    for field, config in pairs(field_configs) do
        fields[field] = FieldConfig.field_type_to_field_class[config.type](field, config)
    end
    return fields
end

function FieldConfig.format(configs)
    local has_date = true

    if table.is_list(configs) then
        for i, field in ipairs(configs) do
            configs[field] = {type = 'field'}
            configs[i] = nil
        end
    end

    local has_date = configs.date
    configs.date = nil

    for field, config in pairs(configs) do
        configs[field] = Field.format(config)
    end

    if has_date ~= false then
        configs.date = {type = 'date'}
    end

    return configs
end


return {
    Field = Field,
    BoolField = BoolField,
    ListField = ListField,
    DateField = DateField,
    FieldConfig = FieldConfig,
}
