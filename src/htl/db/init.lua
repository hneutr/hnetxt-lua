local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")
local Path = require("hl.Path")

local Config = require("htl.config")

local M = {}
M.uri = Config.data_dir:join(Config.get("db").path)
M.test_uri = Path.tempdir:join(Config.get("db").path)

function M.before_test()
    M.setup(M.test_uri)
end

function M.after_test()
    M.test_uri:unlink()
    M.con = nil
end

function M.setup(uri)
    M.con = sqlite({
        uri = tostring(uri or M.uri),
        projects = require("htl.db.projects"),
        urls = require("htl.db.urls"),
        mirrors = require("htl.db.mirrors"),
    })
end

function M.get()
    if not M.con then
        M.setup()
    end

    return M.con
end

return M
