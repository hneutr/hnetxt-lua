local htl = require("htl")

local M

before_each(function()
    htl.before_test()
    M = DB.Paths
end)

after_each(htl.after_test)

describe("persist", function()
    it("+", function()
        M:insert({key = "abc", val = "xyz"})
        assert(#M:get() > 0)
        M:persist()
        assert(#M:get() > 0)
        assert.is_nil(M:where({key = "abc"}))
    end)
end)
