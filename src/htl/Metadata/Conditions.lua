local Condition = require("htl.Metadata.Condition")

local M = Class({
    prefixes = Dict({
        ["#"] = {taxonomy = true, predicates = List({"instance", "subset"})},
    }),
    infixes = Dict({
        [":"] = Condition.default_predicates,
        [","] = {expect = true},
    }),
    suffixes = Dict({
        ["!"] = {exclude = true},
        ["~"] = {recurse = true},
    }),
    cli = {
        "conditions",
        args = "*",
        default = List(),
        action = "concat",
        description = List({
            "filter conditions:",
            "    x      [x = str]        →   predicate: x",
            "    x      [x = path]       →   object: x",
            "   +x      [x = str]        →   predicate: *x",
            "    x+     [x = str]        →   predicate: x*",
            "   :x      [x = str]        →   predicate: *.x",
            "   #x      [x = str|path]   →   predicate: subset|instance, object: x",
            "    x!     [x = query]      →   exclude x",
            "    x~     [x = query]      →   recursively match x",
            "    x, y                    →   x|y",
        }):join("\n"),
    }
})

function M:new(conditions, path)
    local instance = setmetatable(
        {
            conditions = M.parse(conditions),
            rows = List(),
        },
        self
    )

    if path then
        instance.urls = Set(DB.urls:get({contains = {path = tostring(path / "*")}}):col('id'))
    end

    instance:apply_conditions()

    return instance
end

function M:apply_conditions()
    local exclusions = Set()
    self.conditions:foreach(function(c)
        local rows = c:get()
        local subjects = Set(rows:col('subject'))

        if c.exclude then
            exclusions = exclusions + subjects
        else
            self.urls = self.urls and self.urls * subjects or subjects
            self.rows:extend(rows)
        end
    end)

    self.urls = self.urls - exclusions
    self.rows = self.rows:filter(function(r) return self.urls:has(r.subject) end)
    self.urls = self.urls:vals()
end

function M.parse(elements)
    local vals = List({Condition:new()})

    elements:foreach(function(element)
        local parts, has_prefixes, has_suffixes = M.parse_element(element)

        if has_prefixes and not vals[#vals]:is_empty() then
            vals:append(Condition:new())
        end

        parts:reverse()
        while #parts > 0 do
            local part = parts:pop()
            if not vals[#vals]:apply(part) then
                vals:append(Condition:new())
                parts:append(part)
            end
        end

        if has_suffixes then
            vals:append(Condition:new())
        end
    end)

    vals = vals:filter(function(c) return not c:is_empty() end)
    vals:foreachm("format_objects")

    return vals
end

function M.parse_element(element)
    local parts = element:partition(M.infixes:keys()):map(function(p)
        return M.infixes[p] or p
    end)

    local prefixes, suffixes
    parts[1], prefixes = M.parse_affix("prefixes", parts[1])
    parts[#parts], suffixes = M.parse_affix("suffixes", parts[#parts])

    return List():extend(prefixes, parts, suffixes), #prefixes > 0, #suffixes > 0
end

function M.parse_affix(affix, val)
    if type(val) ~= 'string' then
        return val, List()
    end

    local parse_fn = affix == "prefixes" and string.removeprefix or string.removesuffix

    local affixes = List()
    local len
    repeat
        len = #val
        M[affix]:foreach(function(char, action)
            val, found = parse_fn(val, char)
            if found then affixes:append(action) end
        end)
    until #val == len

    return val, affixes
end

return M
