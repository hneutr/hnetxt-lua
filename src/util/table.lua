function table.merge(tbl, other, ...)
    tbl = tbl or {}

    if other and #other > 0 then
        for _, v in ipairs(other) do 
            table.insert(tbl, v)
        end
    end

    if ... then
        tbl = table.merge(tbl, ...)
    end
        
    return tbl
end

return table
