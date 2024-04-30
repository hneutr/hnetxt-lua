local sqlite = require("sqlite.db")

local M = {}
M.schema = Dict({
    projects = require("htl.db.projects"),
    urls = require("htl.db.urls"),
    metadata = require("htl.db.metadata"),
    samples = require("htl.db.samples"),
    Paths = require("htl.db.Paths"),
    Log = require("htl.db.Log"),
    Relations = require("htl.db.Relations"),
    Elements = require("htl.db.Elements"),
})

function M.init()
    DB = sqlite({uri = tostring(Conf.paths.db_file)})

    M.schema:foreach(function(key, _tbl)
        DB[key] = _tbl
        SqliteTable.set_db(_tbl, DB)
    end)
end

function M.clean()
    DB.urls:clean()
end

return M
