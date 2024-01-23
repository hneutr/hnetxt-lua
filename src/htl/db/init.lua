local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")
local Path = require("hl.Path")

local Config = require("htl.config")

-- local strftime = sqlite.lib.strftime

local M = {}
M.uri = Config.data_dir:join(Config.get("db").path)
M.test_uri = Path.tempdir:join(Config.get("db").path)

function M.before_test()
    M.setup(M.test_uri)
end

function M.after_test()
    M.test_uri:unlink()
end

function M.setup(uri)
    return sqlite({
        uri = tostring(uri or M.uri),
        projects = require("htl.db.projects"),
    })
end

return M
