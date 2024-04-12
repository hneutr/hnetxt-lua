local Config = require("htl.Config")

local M = require("htl.db")

before_each(function()
    Config.before_test()
    M.setup()
end)

after_each(function()
    Config.after_test()
end)
