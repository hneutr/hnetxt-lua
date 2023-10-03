local class = require("pl.class")

class.List(require("pl.List"))

function List:extend(l, ...)
    self = self._base.extend(self, l)

    if ... then
        self = self:extend(...)
    end

    return self
end

function List.from(...)
    return List():extend(...)
end

function List.is_listlike(v)
    if type(v) ~= 'table' then
        return false
    end

    if #v > 0 then
        return true
    end

    for _, _ in pairs(v) do
        return false
    end

    return true
end

function List.as_list(v)
    if type(v) ~= 'table' then
        v = {v}
    end

    return List(v)
end

return List
