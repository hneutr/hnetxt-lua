local sqlite = require("sqlite.db")

local M = {
    schema = Dict({
        projects = require("htl.db.projects"),
        urls = require("htl.db.urls"),
        samples = require("htl.db.samples"),
        Paths = require("htl.db.Paths"),
        Log = require("htl.db.Log"),
        Instances = require("htl.db.Instances"),
        Metadata = require("htl.db.Metadata"),
    })
}

function M.init()
    DB = sqlite({uri = tostring(Conf.paths.db_file)})

    M.schema:foreach(function(key, _tbl)
        DB[key] = _tbl
        SqliteTable.set_db(_tbl, DB)
    end)
end

return M
