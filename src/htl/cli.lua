require("htl")

local ArgParse = require("argparse")

local Component = class()
Component.bin_dir = Conf.paths.lib_dir / "bin"
Component.htc_dir = Conf.paths.lib_dir / "src/htc"

Component.keys = List({
    "description",
    "action",
    "target",
    "argname",
    "defmode",
})

function Component:add_subelements() return end
function Component:should_write_shell_content() return false end

function Component:_init(conf, parent, name)
    self.conf = self:format_conf(conf, name)
    self.name = self.conf.name
    self.parent = parent

    self.element = self:set_element()

    self:set_element_keys()
    
    self.element.name_parts = List.from(
        self.parent and self.parent.name_parts or {},
        {self.name}
    )
    
    self:add_subelements()
    
    if self:should_write_shell_content() then
        self:write_shell_content()
    end
end

function Component:write_shell_content() return end

function Component:format_conf(conf, name)
    conf.name = conf.name or name or conf[1]

    local print_fn = Dict.pop(conf, "print")

    if print_fn then
        conf.action = function(args)
            print(print_fn(args))
        end
    end

    return conf
end

function Component:set_element()
    return self.parent[self.type](self.parent, self.name)
end

function Component:set_element_keys()
    self.keys:foreach(function(key)
        local val = self.conf[key]

        if val ~= nil then
            self.element[key](self.element, val)
        end
    end)
end

function Component.shell_fn(name, lines)
    lines:transform(function(l) return "    " .. l end)
    lines:put(string.format("function %s() {", name))
    lines:append("}")
    return lines:join("\n")
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

function Flag:format_conf(conf)
    conf.name = "-" .. conf[1]:removeprefix("+")

    if conf.switch == 'on' then
        conf.default = false
        conf.action = 'store_true'
    elseif conf.switch == 'off' then
        conf.default = true
        conf.action = 'store_false'
    end

    return conf
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

function Command:add_subelements()
    for _, _conf in ipairs(self.conf) do
        self:get_type(_conf)(_conf, self.element)
    end

    for name, _conf in pairs(self.conf.commands or {}) do
        Command(_conf, self.element, name)
    end
end

function Command:should_write_shell_content()
    return self.conf.write_shortcut == true
end

function Command:write_shell_content()
    local content = List({
        self:shell_content(self.name),
        "\n",
        self:test_shell_content(self.name),
    })

    local full_name = self.element.name_parts:join("-")
    local path = self.bin_dir / string.format("%s.sh", full_name)
    
    path:write(content)
    
    self:write_completions()
end

function Command:write_completions()
    local path = Conf.paths.htc_completions_dir / string.format("_%s", self.name)
    if self.name == 'define' then
        print(self.element:get_zsh_complete())
    end
    path:write(self.element:get_zsh_complete())
end

function Command:shell_content(name)
    local str = self.htc_dir / string.format("%s.lua", self.element.name_parts[1])
    
    if #self.element.name_parts > 1 then
        local parts = self.element.name_parts:clone()
        parts[1] = str

        str = parts:join(" ")
    end
    
    str = string.format("luajit %s $@", str)
    
    if self.conf.edit_output then
        str = string.format("nvim $(%s)", str)
    end
    
    return self.shell_fn(name, List({str}))
end

function Command:test_shell_content(name)
    return self.shell_fn("t" .. name, List({
        "htc_test",
        string.format("%s $@", name)
    }))
end

--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--                                   parser                                   --
--                                                                            --
--                                                                            --
--------------------------------------------------------------------------------
local Parser = class(Command)
Parser.type = 'parser'

function Parser:should_write_shell_content() return true end

function Parser:_init(conf)
    Component._init(self, conf)
    
    --[[
    aliases
    open in vim
    command extras: string
    ]]
    -- self.nvim = args.nvim or false
    -- self.extra = args.extra
    -- self.alias = args.alias

    self.element:parse()
end

function Parser:set_element()
    return ArgParse(self.name)
end

return Parser
