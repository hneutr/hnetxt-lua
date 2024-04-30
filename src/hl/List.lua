require("pl.class").List(require("pl.List"))

function List:extend(l, ...)
    if l then
        self = self._base.extend(self, l)
    end

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

function List:all()
    for item in self:iter() do
        if not item then
            return false
        end
    end

    return true
end

function List:any()
    for item in self:iter() do
        if item then
            return item
        end
    end

    return false
end

function List:col(col)
    local l = List()
    for i, item in ipairs(self) do
        l:insert(i, item[col])
    end
    return l
end

return List
