require("htl")

local ArgParse = require("argparse")

local Component = class()
Component.keys = List({
    "description",
    "action",
    "target",
    "argname",
    "defmode",
})

-- function Component:_init()

function Component:attach(parent, conf, name)
    name = name or self:get_name(conf)

    local element = parent[self.type](parent, name)

    self:set_element_keys(element, conf)
    
    element.name_parts = List.from(parent.name_parts or {}, {name})

    return element
end

function Component:set_element_keys(element, conf)
    local print_fn = Dict.pop(conf, "print")

    if print_fn then
        conf.action = function(args)
            print(print_fn(args))
        end
    end

    self.keys:foreach(function(key)
        local val = conf[key]

        if val ~= nil then
            element[key](element, val)
        end
    end)
end

Component.add = Component.attach

function Component:get_name(conf)
    return conf[1]
end

--------------------------------------------------------------------------------
--                                  Argument                                  --
--------------------------------------------------------------------------------
local Argument = class(Component)
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
Option.keys = List.from(Component.keys, {
    'default',
    'convert',
    'count',
    'args',
    'init',
    'hidden',
    'hidden_name',
})

function Option.is_type(conf) return conf[1]:startswith("-") end

--------------------------------------------------------------------------------
--                                    Flag                                    --
--------------------------------------------------------------------------------
local Flag = class(Component)
Flag.type = 'flag'
Flag.keys = List.from(Component.keys, {
    'default',
    'convert',
    'count',
    'hidden',
    'hidden_name',
})

function Flag.is_type(conf)
    return conf[1]:startswith("+")
end

function Flag:get_name(conf)
    return "-" .. conf[1]:removeprefix("+")
end

function Flag:add(parent, conf)
    if conf.switch == 'on' then
        conf.default = false
        conf.action = 'store_true'
    elseif conf.switch == 'off' then
        conf.default = true
        conf.action = 'store_false'
    end

    return self:attach(parent, conf)
end

--------------------------------------------------------------------------------
--                                  Command                                   --
--------------------------------------------------------------------------------
local Command = class(Component)
Command.type = 'command'
Command.keys = List.from(Component.keys, {
    "command_target",
    "require_command",
})
Command.types = List({
    Option,
    Flag,
    Argument,
})

function Command:get_type(conf)
    for _type in self.types:iter() do
        if _type.is_type(conf) then
            return _type
        end
    end
end

function Command:add(parent, conf, name)
    local element = self:attach(parent, conf, name)

    self:add_components(element, conf)
end

function Command:add_components(element, conf)
    for _, _conf in ipairs(conf) do
        self:get_type(_conf):add(element, _conf)
    end

    for name, _conf in pairs(conf.commands or {}) do
        self:add(element, _conf, name)
    end
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

function Parser:_init(conf)
    self.name = conf.name

    --[[
    aliases
    open in vim
    command extras: string
    ]]
    -- self.nvim = args.nvim or false
    -- self.extra = args.extra
    -- self.alias = args.alias


    self.parser = self:get_argparser(self.name, conf)
    
    self:write(self.parser, self.name)
    self.parser:parse()

    return self.parser
end

function Parser:get_argparser(name, conf)
    local parser = ArgParse(name)

    parser.name_parts = List({name})

    self:set_element_keys(parser, conf)
    self:add_components(parser, conf)

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

function Parser:shell_content(name)
    local script_path = self.htc_dir / string.format("%s.lua", name)
    local str = string.format("luajit %s $@", script_path)
    
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
        "    htc_test",
        string.format("    %s $@", name),
        "}"
    }):join("\n")
end

return Parser
