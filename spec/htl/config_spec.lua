local yaml = require("hl.yaml")

local Config = require("htl.Config")

before_each(function()
    Config.before_test()
end)

after_each(function()
    Config.after_test()
end)
