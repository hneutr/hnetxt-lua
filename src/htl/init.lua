local Config = require("htl.Config")
local db = require("htl.db")

local M = {}

function M.before_test()
    Config.before_test()
    db.setup()
end

function M.after_test()
    Config.after_test()
end

function M.init()
    Config.init()
    -- db.init()
end

return {}
