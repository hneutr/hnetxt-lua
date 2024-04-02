local sqlite = require("sqlite.db")
local Dict = require("hl.Dict")

local Config = require("htl.Config")

local M = {}

function M.before_test()
    Config.before_test()
    Config.Nbefore_test()
    M.setup()
end

function M.after_test()
    Config.after_test()
    Config.Nafter_test()
end

function M.setup()
    M.con = sqlite({
        uri = tostring(Config.paths.db_file),
        projects = require("htl.db.projects"),
        urls = require("htl.db.urls"),
        metadata = require("htl.db.metadata"),
        samples = require("htl.db.samples"),
    })
end

function M.get()
    if not M.con then
        M.setup()
    end

    return M.con
end

function M.clean()
    local con = M.get()
    con.urls:clean()
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
