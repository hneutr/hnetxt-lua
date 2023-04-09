function table.merge(tbl, other, ...)
    tbl = tbl or {}
    for k, v in pairs(other) do
        if tbl[k] == nil then
            tbl[k] = other[k]
        elseif type(v) == 'table' then
            tbl[k] = table.merge(tbl[k], v)
        end
    end

    if ... then
        tbl = table.merge(tbl, ...)
    end
        
    return tbl
end


return table
