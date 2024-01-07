local class = require("pl.class")
local List = require("hl.List")
local Dict = require("hl.Dict")

class.Set()

function Set._init(self, vals)
    self._vals = Dict()

    List(vals):foreach(function(v) 
        self:add_val(v)
    end)
end

function Set.add_val(self, val)
    self._vals[val] = true
end

function Set.remove_val(self, val)
    self._vals[val] = nil
end

function Set.has(self, val)
    return self._vals[val] or false
end

function Set.values(self)
    return self._vals:keys()
end

function Set.__tostring(self)
    return '{' .. self:values():join(", ") .. '}'
end

function Set.union(self, other)
    local other_values

    if type(other) == 'table' then
        local mt = getmetatable(other)
        if mt == Set then
            other_values = other:values()
        else
            other_values = other
        end
    else
        other_values = {other}
    end

    return Set(self:values():extend(other_values))
end

Set.__add = Set.union

function Set.intersection(self, other)
    return Set(self:values():clone():filter(function(val) return other:has(val) end))
end

Set.__mul = Set.intersection

function Set.difference(self, other)
    return Set(self:values():clone():filter(function(val) return not other:has(val) end))
end

Set.__sub = Set.difference

function Set.symmetric_difference(self, other)
    local union = self + other
    local intersection = self * other
    return union - intersection
end

Set.__pow = Set.symmetric_difference

function Set.issubset(self, other)
    for k in pairs(self:values()) do
        if not other:has(k) then
            return false
        end
    end

    return true
end

Set.__lt = Set.issubset

function Set.len(self)
    return #self:values()
end

Set.__len = Set.len

function Set.isempty(self)
    return self:len() == 0
end

function Set.__eq(self, other)
    return self < other and other < self
end

function Set.isdisjoint(self, other)
    return Set.isempty(self * other)
end

function Set:add(other)
    local other_values
    if type(other) == 'table' then
        local mt = getmetatable(other)
        if mt == Set then
            other_values = other:values()
        else
            other_values = other
        end
    else
        other_values = {other}
    end

    List(other_values):foreach(function(val)
        self:add_val(val)
    end)
end

function Set:foreach(...)
    self:values():foreach(...)
end

return Set
