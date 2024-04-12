require("hl")

local Config = require("htl.Config")
local db = require("htl.db")

local M = {}

M.test_dir = Conf.paths.test_dir

function M.before_test()
    Config.root = M.test_dir
    M.init()
end

function M.after_test()
    M.test_dir:rmdir(true)
    Config.root = Path.home
end

function M.init()
    Config.init()
    db.init()
end

M.init()

return M
