require("htl")

local ArgParse = require("argparse")

--------------------------------------------------------------------------------
--                                 Component                                  --
--------------------------------------------------------------------------------
local Component = class()

Component.keys = List({
    "description",
    "action",
    "target",
    "argname",
})

function Component:_init(conf, parent)
    self.conf = self:format_conf(conf)
    self.name = self.conf.name

    self:set_parent(parent)
    self:set_element()
    self:set_element_keys()
end

function Component:set_parent(parent)
    self.parent = parent
    self.parser = self.parent.parser
end

function Component:format_conf(conf)
    conf.name = conf.name or conf[1]
    return conf
end

function Component:set_element()
    self.element = self.parent.element[self.type](self.parent.element, self.name)
end

function Component:set_element_keys()
    self.keys:foreach(function(key)
        local val = self.conf[key]

        if val ~= nil then
            self.element[key](self.element, val)
        end
    end)
end

function Component.shell_function(name, lines)
    lines = List.as_list(lines)
    lines:transform(function(l) return "    " .. l end)
    lines:put(string.format("function %s() {", name))
    lines:append("}")
    return lines:join("\n")
end

function Component.shell_alias(lhs, rhs)
    return string.format('alias %s="%s"', lhs, rhs)
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

function Flag.is_type(conf) return conf[1]:startswith("+") end

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
Command.subcomponent_types = List({
    Option,
    Flag,
    Argument,
})

function Command:_init(conf, parent)
    Component._init(self, conf, parent)

    self.name_parts = List.from(self.parent.name_parts, {self.name})

    self:add_alias()
    self:add_subcomponents()
end

function Command:format_conf(conf)
    if conf.alias == true then
        conf.alias = conf.name
    end

    local print_fn = Dict.pop(conf, "print")

    if print_fn then
        conf.action = function(args)
            io.write(tostring(print_fn(args)) .. "\n")
        end
    end

    local edit_fn = Dict.pop(conf, "edit")

    if edit_fn then
        conf.action = function(args)
            local result = edit_fn(args)

            if conf.call_with then
                result = string.format("%s %s", result, conf.call_with)
            end

            os.execute(string.format("< /dev/tty nvim %s", result))
        end
    end

    conf.commands = Dict(conf.commands):foreach(function(k, v) v.name = k end):values()

    return conf
end

function Command:add_subcomponent(conf)
    for Subcomponent in self.subcomponent_types:iter() do
        if Subcomponent.is_type(conf) then
            Subcomponent(conf, self)
            return
        end
    end
end

function Command:add_alias()
    if self.conf.alias then
        self.parser.aliases:append(self.shell_alias(self.conf.alias, self.name_parts:join(" ")))
    end
end

function Command:add_subcomponents()
    for _, _conf in ipairs(self.conf) do
        self:add_subcomponent(_conf)
    end

    self.conf.commands:sorted(function(a, b)
        return a.name < b.name
    end):foreach(Command, self)
end

--------------------------------------------------------------------------------
--                                   Parser                                   --
--------------------------------------------------------------------------------
local Parser = class(Command)
Parser.type = 'parser'

Parser.bin_dir = Conf.paths.lib_dir / "bin"

function Parser:_init(conf)
    Command._init(self, conf)

    self:write_shell_content()

    self.element:parse()
end

function Parser:set_parent()
    self.parent = {name_parts = {}}
    self.parser = self
    self.aliases = List()
end

function Parser:set_element()
    self.element = ArgParse(self.name)
end

function Parser:completions_path()
    return Conf.paths.htc_completions_dir / string.format("_%s", self.name)
end

function Parser:bin_path()
    return self.bin_dir / string.format("%s.sh", self.name)
end

function Parser:write_shell_content()
    self:bin_path():write(self.aliases:join("\n\n"))
    self:completions_path():write(self.element:get_zsh_complete())
end

return Parser
