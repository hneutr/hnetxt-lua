require("pl.class").Dict()

function Dict:_init(...)
    self:update(...)
end

function Dict.update(d, d2, ...)
    if d == nil then
        d = d2
    elseif type(d) == 'table' and type(d2) == 'table' then
        for k, v2 in pairs(Dict.delist(d2)) do
            d[k] = Dict.update(d[k], v2)
        end
    end

    if ... then
        d = Dict.update(d, ...)
    end
        
    return d
end

function Dict.delist(t)
    local _t = {}
    for k, v in pairs(t) do
        _t[k] = v
    end

    for i, v in ipairs(t) do
        _t[i] = nil
    end

    return _t
end

function Dict.from_list(list, fn)
    local d = Dict()
    list:foreach(function(item)
        local key, val = fn(item)
        d[key] = val
    end)
    
    return d
end

function Dict.keys(d)
    local keys = List()
    for key, _ in pairs(d) do
        keys:append(key)
    end

    return keys
end

function Dict.values(d)
    local values = List()
    for _, value in pairs(d) do
        values:append(value)
    end

    return values
end

function Dict:foreachk(fun, ...)
    for k, v in pairs(self) do
        fun(k, ...)
    end
end

function Dict:foreachv(fun, ...)
    for k, v in pairs(self) do
        fun(v, ...)
    end
end

function Dict:foreach(fun, ...)
    for k, v in pairs(self) do
        fun(k, v, ...)
    end
end

function Dict:transformk(fun, ...)
    local _d = Dict()
    for k, v in pairs(self) do
        self[k] = nil
        _d[fun(k, ...)] = v
    end

    self:update(_d)

    return self
end

function Dict:transformv(fun, ...)
    for k, v in pairs(self) do
        self[k] = fun(v, ...)
    end

    return self
end

function Dict:filterk(fun, ...)
    for k, v in pairs(self) do
        if not fun(k, ...) then
            self[k] = nil
        end
    end

    return self
end

function Dict:filterv(fun, ...)
    for k, v in pairs(self) do
        if not fun(v, ...) then
            self[k] = nil
        end
    end

    return self
end

function Dict.default(dict, key, val)
    if dict[key] == nil then
        dict[key] = val
    end

    return dict[key]
end

function Dict.get(dict, key, ...)
    local value = dict[key] or Dict()

    if ... then
        value = value:get(...)
    end

    return value
end

function Dict.set(dict, keys, val)
    if val == nil then
        val = Dict()
    end
    keys = List(keys):reverse()

    local d = dict
    while #keys > 1 do
        local key = keys:pop()

        if not d[key] then
            d[key] = Dict()
        end

        d = d[key]
    end

    d[keys:pop()] = val
    return dict
end

function Dict:has(key, ...)
    local has = self:keys():contains(key)

    if has and ... then
        has = self[key]:has(...)
    end

    return has
end

function Dict:__tostring()
    local lines = List()

    self:keys():sorted():foreach(function(k)
        lines:extend(string.format("%s = %s", k, tostring(self[k])):split("\n"))
    end)
    
    lines:transform(function(l) return "  " .. l end)

    if #lines == 0 then
        lines:append("{}")
    else
        lines:put("{")
        lines:append("}")
    end

    return lines:join("\n")
end

function Dict:raw()
    local raw = {}

    self:foreach(function(k, v)
        if type(v) ~= 'table' then
            v = Dict(v):raw()
        end

        raw[k] = v
    end)

    return raw
end

return Dict
