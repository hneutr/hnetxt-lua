local HTL = require("htl")

local M = require("htl.db")

before_each(function()
    HTL.before_test()
    M.setup()
end)

after_each(function()
    HTL.after_test()
end)
