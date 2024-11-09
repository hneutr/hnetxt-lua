require("pl.class").List(require("pl.List"))

function List.extend(list, ...)
    for _, l in ipairs({...}) do
        if l then
            list = list._base.extend(list, l)
        end
    end
    return list
end

function List.from(...) return List():extend(...) end

function List.is_like(v)
    if type(v) ~= 'table' then
        return false
    end

    if #v > 0 then
        return true
    end

    for _, _ in pairs(v) do
        return false
    end

    return false
end

function List.as_list(v)
    if type(v) ~= 'table' then
        v = {v}
    end

    return List(v)
end

function List.all(list)
    for item in list:iter() do
        if not item then
            return false
        end
    end

    return true
end

function List.any(list)
    for item in list:iter() do
        if item then
            return item
        end
    end

    return false
end

function List.notnil(list)
    list = list:filter(function(i) return i ~= nil end)
    return list
end

function List.col(list, col)
    local l = List()
    for i, item in ipairs(list) do
        l:insert(i, item[col])
    end
    return l
end

function List.unique(list)
    local l = List()
    for i, item in ipairs(list) do
        if not l:contains(item) then
            l:append(item)
        end
    end

    return l
end

function List.filterm(list, method, ...)
    local vargs = ...
    return list:filter(function(item) return item[method](item, vargs) end)
end

return List
