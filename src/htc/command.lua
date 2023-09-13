require("approot")("/Users/hne/lib/hnetxt-cli/")

string = require("hl.string")
local Dict = require("hl.Dict")
local List = require("hl.List")

local Object = require('hl.object')

local Component = Object:extend()
Component.config_key = 'comp'
Component.keys = {
    "description",
    "action",
    "target",
    "argname",
    "defmode",
}
Component.type = ''

function Component:attach(parent, settings, name)
    name = name or self:get_name(settings)

    local object = parent[self.type](parent, name)

    for _, key in ipairs(self.keys) do
        if settings[key] ~= nil then
            object[key](object, settings[key])
        end
    end

    return object
end

function Component:add(...)
    return self:attach(...)
end

function Component.is_type(settings)
    return false
end

function Component:get_name(settings)
    return settings[1]
end

function Component:get_names(settings)
    local names = self:get_name(settings):split()
    return {short = names[1], long = names[2]}
end

----------------------------------------------------------------------------------
----                                   Mutex                                    --
----------------------------------------------------------------------------------
local Mutex = Component:extend()
Mutex.config_key = 'mutexes'
Mutex.type = 'mutex'
Mutex.keys = {}

function Mutex:add_all(parent, settings, components)
    for _, mutex_keys in ipairs(settings[self.config_key] or {}) do
        local mutex = List()
        for _, key in ipairs(mutex_keys) do
            mutex:append(components[key])
        end

        self:attach(parent, mutex)
    end
end

function Mutex:attach(parent, mutex)
    parent[self.type](parent, unpack(mutex))
end

--------------------------------------------------------------------------------
--                                  Argument                                  --
--------------------------------------------------------------------------------
local Argument = Component:extend()
Argument.config_key = 'args'
Argument.type = 'argument'
Argument.keys = List.from(Component.keys, {
    'default',
    'convert',
    'args',
    'choices',
    'hidden',
    'hidden_name',
})

function Argument.is_type(settings)
    return true
end

--------------------------------------------------------------------------------
--                                   Option                                   --
--------------------------------------------------------------------------------
local Option = Component:extend()
Option.type = 'option'
Option.config_key = 'opts'
Option.keys = List.from(Component.keys, {
    'default',
    'convert',
    'count',
    'args',
    'init',
    'hidden',
    'hidden_name',
})

function Option.is_type(settings)
    return settings[1]:startswith("-")
end

--------------------------------------------------------------------------------
--                                    Flag                                    --
--------------------------------------------------------------------------------
local Flag = Component:extend()
Flag.config_key = 'flags'
Flag.type = 'flag'
Flag.keys = List.from(Component.keys, {
    'default',
    'convert',
    'count',
    'hidden',
    'hidden_name',
})

function Flag.is_type(settings)
    return settings[1]:startswith("+")
end

function Flag:get_name(settings)
    return "-" .. settings[1]:removeprefix("+")
end

function Flag:add(parent, settings)
    settings = self:set_switch_settings(settings)

    local component = self:attach(parent, settings)

    if settings.add_off then
        Mutex():attach(parent, {component, self:add_off(parent, settings)})
    end

    return component
end

function Flag:set_switch_settings(settings)
    if settings.switch == 'on' then
        settings.default = false
        settings.action = 'store_true'
    elseif settings.switch == 'off' then
        settings.default = true
        settings.action = 'store_false'
    end

    return settings
end

function Flag:add_off(parent, settings)
    local names = self:get_names(settings)

    return self:attach(parent, {
        "-n" .. names.short:removeprefix("-"),
        default = true,
        target = names.long:removeprefix("--"):gsub("%-", "_"),
        description = string.format("don't %s", settings.description),
        action = 'store_false',
    })
end

--------------------------------------------------------------------------------
--                                  Command                                   --
--------------------------------------------------------------------------------
local Command = Component:extend()
Command.type = 'command'
Command.config_key = 'commands'
Command.keys = List.from(Component.keys, {
    "command_target",
    "require_command",
})
Command.component_types = {
    Option(),
    Flag(),
    Argument(),
}

function Command:add_all(parent, settings)
    local components = {}
    for name, subsettings in pairs(settings[self.config_key] or {}) do
        components[name] = self:add(parent, subsettings, name)
    end

    return components
end

function Command:get_component_type(settings)
    for _, component_type in ipairs(self.component_types) do
        if component_type.is_type(settings) then
            return component_type
        end
    end
end

function Command:add(parent, settings, name)
    local object = self:attach(parent, settings, name)

    local components = Dict()
    for _, _settings in ipairs(settings) do
        local component_type = self:get_component_type(_settings)
        local component_name = component_type:get_name(_settings)
        components[component_name] = component_type:add(object, _settings)
    end

    Mutex():add_all(object, settings, components)
    self:add_all(object, settings)

    return object
end


return Command
