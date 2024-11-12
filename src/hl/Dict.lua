require("pl.class").Dict()

local M = Dict

local defaults = {}

function M.update(d, d2, ...)
    if d == nil then
        d = d2
    elseif type(d) == 'table' and type(d2) == 'table' then
        for k, v2 in pairs(M.delist(d2)) do
            d[k] = d[k] == nil and v2 or M.update(d[k], v2)
        end
    end

    if ... then
        d = M.update(d, ...)
    end

    return d
end

M._init = M.update

function M.set_default(d, val)
    if not defaults[val] then
        local fn

        if val == M then
            fn = function() return M():set_default(M) end
        elseif type(val) == 'table' or type(val) == 'function' then
            fn = function(self, key) return val() end
        else
            fn = function() return val end
        end

        defaults[val] = function(self, key)
            if not M[key] and not rawget(self, key) then
                rawset(self, key, fn())
            end

            return M[key] or rawget(self, key)
        end
    end

    return setmetatable(d, {__index = defaults[val]})
end

function M.is_like(v)
    return type(v) == 'table' and #v == 0
end

function M.delist(t)
    local _t = {}
    for k, v in pairs(t) do
        _t[k] = v
    end

    for i, _ in ipairs(t) do
        _t[i] = nil
    end

    return _t
end

function M.from_list(list, fn)
    local d = M()
    list:foreach(function(item)
        local key, val = fn(item)
        d[key] = val
    end)

    return d
end

function M.keys(d)
    local keys = List()
    for key, _ in pairs(d) do
        keys:append(key)
    end

    return keys
end

function M.values(d)
    local values = List()
    for _, value in pairs(d) do
        values:append(value)
    end

    return values
end

function M:foreachk(fun, ...)
    for k, _ in pairs(self) do
        fun(k, ...)
    end
    return self
end

function M:foreachv(fun, ...)
    for _, v in pairs(self) do
        fun(v, ...)
    end
    return self
end

function M:foreach(fun, ...)
    for k, v in pairs(self) do
        fun(k, v, ...)
    end

    return self
end

function M:transformk(fun, ...)
    local _d = M()
    for k, v in pairs(self) do
        self[k] = nil
        _d[fun(k, ...)] = v
    end

    self:update(_d)

    return self
end

function M:transformv(fun, ...)
    for k, v in pairs(self) do
        self[k] = fun(v, ...)
    end

    return self
end

function M:filterk(fun, ...)
    for k, _ in pairs(self) do
        if not fun(k, ...) then
            self[k] = nil
        end
    end

    return self
end

function M:filterv(fun, ...)
    for k, v in pairs(self) do
        if not fun(v, ...) then
            self[k] = nil
        end
    end

    return self
end

function M:__tostring()
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

function M.print(d)
    print(M(d))
end

function M:pop(key)
    local val = self[key]
    self[key] = nil
    return val
end

function M.get(dict, key, ...)
    local value = dict[key] or M()

    if ... then
        value = value:get(...)
    end

    return value
end

function M:has(key, ...)
    local has = self:keys():contains(key)

    if has and ... then
        has = self[key]:has(...)
    end

    return has
end

return M
-- return M
