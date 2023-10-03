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

function Dict.from(...)
    return Dict():update(...)
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

return Dict
