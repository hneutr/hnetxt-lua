local M = {}

local Condition = Class()

function Condition:new(conf)
    local instance = setmetatable(conf or {}, self)
    instance.predicates = instance.predicates or List()
    instance.objects = instance.objects or List()
    instance.expect = false

    return instance
end

function Condition:is_empty()
    return #self.predicates == 0 and #self.objects == 0
end

function Condition:default_predicates()
    self.predicates = #self.predicates > 0 and self.predicates or List({"*"})
end

function Condition:add(element)
    local is_url = type(element) == "number"

    if is_url or self.taxonomy then
        self:default_predicates()

        if #self.objects == 0 or self.expect then
            self.objects:append(element)
        end
    elseif #self.predicates == 0 or self.expect then
        self.predicates:append(element)
    end

    self.expect = false
end

local Conditions = {}

Conditions.grammar = {
    prefixes = List({
        {
            char = "#",
            fields = {taxonomy = true, predicates = List({"subset", "instance"})},
        },
        {
            char = "!",
            fields = {exclude = true},
        },
        {
            char = "~",
            skip = "~/",
            fields = {recurse = true},
        },
    }),
    infixes = List({
        {
            char = ":",
            action = function(condition) condition:default_predicates() end,
        },
        {
            char = ",",
            action = function(condition) condition.expect = true end,
        },
    })
}


function Conditions.parse_prefixes(s)
    local fields = Dict()
    local len

    repeat
        len = #s
        for prefix in Conditions.grammar.prefixes:iter() do
            local skip = prefix.skip and s:startswith(prefix.skip)
            if not skip and s:startswith(prefix.char) then
                s = s:removeprefix(prefix.char)
                fields:update(prefix.fields)
            end
        end
    until #s == len

    return s, fields
end

function Conditions.parse_infixes(s)
    local pattern = ("[%s]"):format(Conditions.grammar.infixes:col('char'):mapm("escape"))
    local parts = List()
    while #s > 0 do
        local index = s:find(pattern)
        parts:append(s:sub(1, index and math.max(index - 1, 1)))
        s = s:sub(#parts[#parts] + 1)
    end
    return parts
end

function Conditions.add_element(condition, element)
    for infix in Conditions.grammar.infixes:iter() do
        if element == infix.char then
            return infix.action(condition)
        end
    end

    local path = Path.from_cli(element)
    local url = path:exists() and DB.urls:get_file(path)
    condition:add(url and url.id or element)
end

function Conditions.add(conditions, element)
    if #conditions == 0 then
        conditions:append(Condition:new())
    end

    local prefix_fields
    element, prefix_fields = Conditions.parse_prefixes(element)

    local c = conditions[#conditions]

    if #prefix_fields:keys() > 0  then
        if not c:is_empty() then
            conditions:append(Condition:new(prefix_fields))
            c = conditions[#conditions]
        end

        prefix_fields:foreach(function(k, v) c[k] = v end)
    end

    Conditions.parse_infixes(element):foreach(function(part) Conditions.add_element(c, part) end)
end

M.Condition = Condition
M.Conditions = Conditions

M.cli = {
    name = "metadata",
    alias = "on",
    {
        "conditions",
        args = "*",
        default = List(),
        action = function(args, _, elements)
            List(elements):foreach(function(element)
                Conditions.add(args.conditions, element)
            end)
        end,
        action = "concat",
        description = List({
            "filter conditions:",
            "    x      [x = str]        →   predicate: x",
            "    x      [x = path]       →   object: x",
            "   +x      [x = str]        →   predicate: *x",
            "    x+     [x = str]        →   predicate: x*",
            "   :x      [x = str]        →   predicate: *.x",
            "   #x      [x = str|path]   →   predicate: subset|instance, object: x",
            "   !x      [x = query]      →   exclude x",
            "   ~x      [x = query]      →   recursively match x",
            "    x, y                    →   x|y",
        }):join("\n"),
    },
    {"-p --path", default = Path.cwd(), convert = Path.from_cli},
    {"+i", target = "include_instances", description = "include instances", switch = "on"},
    {"+I", target = "instances_only", description = "only print instances", switch = "on"},
    {"+a", target = "by_attribute", description = "by attribute", switch = "on"},
    {"+V", target = "include_attribute_values", description = "exclude attribute values", switch = "off"},
    -- print = require("htc.Metadata.Ontology"),
    action = function(args)
        args.conditions:foreach(Dict.print)
        -- print(args.conditions)
    end,
}

return M
