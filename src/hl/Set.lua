local List = require("hl.List")
local Dict = require("hl.Dict")

require("pl.class").Set()

function Set._init(self, vals)
    self._vals = Dict()

    List(vals):foreach(function(v)
        self:add_val(v)
    end)
end

function Set.add_val(self, val)
    self._vals[val] = true
    return self
end

function Set.has(self, val)
    return self._vals[val] or false
end

function Set.vals(self)
    return self._vals:keys()
end

function Set.__tostring(self)
    return '{' .. self:vals():join(", ") .. '}'
end

function Set.__get_vals(thing, ...)
    local vals
    if type(thing) == 'table' then
        if getmetatable(thing) == Set then
            vals = thing:vals()
        else
            vals = thing
        end
    else
        vals = {thing}
    end

    vals = List(vals)

    if ... then
        vals:extend(Set.__get_vals(...))
    end

    return vals
end

function Set.union(...)
    return Set(Set.__get_vals(...))
end

Set.__add = Set.union

function Set.intersection(self, other)
    return Set(self:vals():clone():filter(function(val) return other:has(val) end))
end

Set.__mul = Set.intersection

function Set.difference(self, ...)
    local other = Set.union(...)
    return Set(self:vals():clone():filter(function(val) return not other:has(val) end))
end

Set.__sub = Set.difference

function Set.symmetric_difference(self, other)
    local union = self + other
    local intersection = self * other
    return union - intersection
end

Set.__pow = Set.symmetric_difference

function Set.issubset(self, other)
    for _, k in ipairs(self:vals()) do
        if not other:has(k) then
            return false
        end
    end

    return true
end

Set.__lt = Set.issubset

function Set.len(self)
    return #self:vals()
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
    Set.__get_vals(other):foreach(function(val) self:add_val(val) end)
    return self
end

function Set:remove(other)
    Set.__get_vals(other):foreach(function(val) self._vals[val] = nil end)
    return self
end


function Set:foreach(...)
    self:vals():foreach(...)
end

return Set
