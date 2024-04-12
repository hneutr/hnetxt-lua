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
    Paths = require("htl.db.Paths"),
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

return M
