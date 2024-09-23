require("htl")

local M = {}

local ArgParse = require("argparse")

local Component = class()
Component.config_key = 'comp'
Component.type = ''
Component.keys = {
    "description",
    "action",
    "target",
    "argname",
    "defmode",
}

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

Component.add = Component.attach
Component.is_type = function() return false end

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
local Mutex = class(Component)
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
local Argument = class(Component)
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

Argument.is_type = function() return true end

--------------------------------------------------------------------------------
--                                   Option                                   --
--------------------------------------------------------------------------------
local Option = class(Component)
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
local Flag = class(Component)
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
        Mutex:attach(parent, {component, self:add_off(parent, settings)})
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
local Command = class(Component)
Command.type = 'command'
Command.config_key = 'commands'
Command.keys = List.from(Component.keys, {
    "command_target",
    "require_command",
})
Command.component_types = {
    Option,
    Flag,
    Argument,
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
    if settings then
        local print_fn = Dict.pop(settings, "print")

        if print_fn then
            settings.action = function(args)
                print(print_fn(args))
            end
        end
    end

    local object = self:attach(parent, settings, name)

    local components = Dict()
    for _, _settings in ipairs(settings) do
        local component_type = self:get_component_type(_settings)
        local component_name = component_type:get_name(_settings)
        components[component_name] = component_type:add(object, _settings)
    end

    Mutex:add_all(object, settings, components)
    self:add_all(object, settings)

    return object
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   parser                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Parser = class(Command)
Parser.bin_dir = Conf.paths.lib_dir / "bin"
Parser.htc_dir = Conf.paths.lib_dir / "src/htc"

function Parser:_init(name, conf, args)
    args = args or {}
    self.name = name
    self.nvim = args.nvim or false
    self.extra = args.extra
    self.alias = args.alias

    --[[
    aliases
    open in vim
    command extras: string
    ]]

    self.parser = self:get_argparser(self.name, conf)
    
    self:write(self.parser, self.name)
    self.parser:parse()

    return self.parser
end

function Parser:get_argparser(name, conf)
    local parser = ArgParse(name)

    if conf then
        local print_fn = Dict.pop(conf, "print")

        if print_fn then
            conf.action = function(args)
                print(print_fn(args))
            end
        end
    end

    for _, key in ipairs(self.keys) do
        if conf[key] ~= nil then
            parser[key](parser, conf[key])
        end
    end

    local components = Dict()
    for _, _conf in ipairs(conf) do
        local component_type = self:get_component_type(_conf)
        local component_name = component_type:get_name(_conf)
        components[component_name] = component_type:add(parser, _conf)
    end

    Mutex:add_all(parser, conf, components)
    self:add_all(parser, conf)
    return parser
end

function Parser:write(parser, name)
    local content = List({
        self:shell_content(name),
        "\n",
        self:test_shell_content(name),
    })

    local path = self.bin_dir / string.format("%s_lib.sh", name)
    path:write(content)
    
    self:write_completions(parser, name)
end

function Parser:write_completions(parser, name)
    local path = Conf.paths.htc_completions_dir / string.format("_%s", name)
    path:write(parser:get_zsh_complete())
end

function Parser:script_path(name)
    return self.htc_dir / string.format("%s.lua", name)
end

function Parser:shell_content(name)
    local str = string.format("luajit %s $@", self:script_path(name))
    
    if self.nvim then
        str = string.format("nvim $(%s)", str)
    end
    
    return List({
        string.format("function %s() {", name),
        string.format("    %s", str),
        "}",
    }):join("\n")
end

function Parser:test_shell_content(name)
    return List({
        string.format("function t%s() {", name),
        "    local START_DIR=$PWD",
        string.format("    cd %s", Conf.paths.lib_dir),
        "    luarocks --lua-version 5.1 make > /dev/null",
        "    cd $START_DIR",
        string.format("    %s $@", name),
        "}"
    }):join("\n")
end

M.Parser = Parser

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                  testing                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
-- local MParser = class()
--
-- MParser.keys = List({
--     "name",
--     "description",
--     "require_command",
--     "action",
-- })
--
-- function MParser:_init(conf)
--     self.conf = Dict(conf)
--
--     self.name = self.conf["name"]
--     self.element = ArgParse(self.name, self.conf.description)
--
--     self:set_require_command()
--     self:set_action()
--
--     self.element:parse()
-- end
--
-- function MParser:set_require_command()
--     local val = self.conf.require_command
--     if val ~= nil then
--         self.element:require_command(val)
--     end
-- end
--
-- function MParser:set_action()
--     if self.conf.print then
--         self.conf.action = function(args)
--             print(self.conf.print(args))
--         end
--     end
--
--     local val = self.conf.action
--
--     if val then
--         self.element:action(val)
--     end
-- end
--
-- function MParser:add_
--
-- function MParser:add_commands()
--     Dict(self.conf.commands):foreach(function(name, conf)
--         self.element:command()
--
--     end)
-- end
--
-- M.MParser = MParser

--[[
-- comp:
--     description
--     action
--     target
--     argname
--     defmode
-- args:
--     description
--     action
--     target
--     argname
--     defmode
--     default
--     convert
--     args
--     choices
--     hidden
--     hidden_name
-- flags:
--     description
--     action
--     target
--     argname
--     defmode
--     default
--     convert
--     count
--     hidden
--     hidden_name
-- opts:
--     description
--     action
--     target
--     argname
--     defmode
--     default
--     convert
--     count
--     args
--     init
--     hidden
--     hidden_name
-- commands:
--     description
--     action
--     target
--     argname
--     defmode
--     command_target
--     require_command










Parser = class({
   _arguments = {},
   _options = {},
   _commands = {},
   _mutexes = {},
   _groups = {},
   _require_command = true,
   _handle_options = true
}, {
   args = 3,
   name
   description
   epilog
   usage
   help
   require_command
   handle_options
   action
   command_target
   help_vertical_space
   usage_margin
   usage_max_width
   help_usage_margin
   help_description_margin
   help_max_width
})

local Command = class({
   _aliases = {}
}, {
   args = 3,
   multiname,
   description
   epilog
   target
   usage
   help
   require_command
   handle_options
   action
   command_target
   help_vertical_space
   usage_margin
   usage_max_width
   help_usage_margin
   help_description_margin
   help_max_width
   hidden
}, Parser)

local Argument = class({
   _minargs = 1,
   _maxargs = 1,
   _mincount = 1,
   _maxcount = 1,
   _defmode = "unused",
   _show_default = true
}, {
   args = 5,
   name
   description
   option_default,
   convert
   args,
   target
   defmode
   show_default
   argname
   hidden
   option_action,
   option_init
})

local Option = class({
   _aliases = {},
   _mincount = 0,
   _overwrite = true
}, {
   args = 6,
   multiname,
   description
   option_default,
   convert
   args
   count
   target
   defmode
   show_default
   overwrite
   argname
   hidden
   option_action,
   option_init
}, Argument)

local Flag = class({
   _aliases = {},
   _mincount = 0,
   _overwrite = true
}, {
    args = 6,
    multiname,
    description
    option_default,
    convert
    args
    count
    target
    defmode
    show_default
    overwrite
    argname
    hidden
    option_action,
    option_init
}, Argument)

]]

return M
