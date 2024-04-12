local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local M = {}
M.schema = Dict({
    projects = require("htl.db.projects"),
    urls = require("htl.db.urls"),
    metadata = require("htl.db.metadata"),
    samples = require("htl.db.samples"),
    Taxa = require("htl.db.Taxa"),
    Relations = require("htl.db.Relations"),
    Log = require("htl.db.Log"),
})

function M.init()
    DB = sqlite({uri = tostring(Conf.paths.db_file)})

    M.schema:foreach(function(key, _tbl)
        DB[key] = _tbl
        tbl.set_db(_tbl, DB)
    end)
end

function M.clean()
    DB.urls:clean()
end

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
