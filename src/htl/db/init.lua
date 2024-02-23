local sqlite = require("sqlite.db")

local Config = require("htl.Config")

local M = {}

function M.before_test()
    Config.before_test()
    M.setup()
end

function M.after_test()
    Config.after_test()
end

function M.setup()
    M.con = sqlite({
        uri = tostring(Config.paths.db_file),
        projects = require("htl.db.projects"),
        urls = require("htl.db.urls"),
        metadata = require("htl.db.metadata"),
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

return M
