require("hl")

local Config = require("htl.Config")
local db = require("htl.db")

local M = {
    test_dir = Conf.paths.test_dir
}

function M.before_test()
    Config.root = M.test_dir
    Config.init()
    db.init()
end

function M.after_test()
    M.test_dir:rmdir(true)
    Config.root = Path.home
end

return M
