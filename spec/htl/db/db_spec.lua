local htl = require("htl")

local M = require("htl.db")

before_each(function()
    htl.before_test()
    M.setup()
end)

after_each(function()
    htl.after_test()
end)
