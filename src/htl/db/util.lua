local M = {}

function M.join(rows, to_join, id_col, to_col)
    return M.map_row_to_col(rows, to_join:get(), id_col, to_col)
end

function M.map_row_to_col(rows, to_map, id_col, map_col)
    map_col = map_col or id_col
    
    local id_to_row = Dict()
    to_map:foreach(function(r)
        id_to_row[r.id] = r
    end)

    rows = rows:filter(function(row)
        return row[id_col] ~= nil and id_to_row[row[id_col]] ~= nil
    end)

    rows:foreach(function(row)
        row[map_col] = id_to_row[row[id_col]]
    end)

    return rows
end

return M
