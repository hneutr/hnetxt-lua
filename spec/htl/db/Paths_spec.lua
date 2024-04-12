local HTL = require("htl")

local M

before_each(function()
    HTL.before_test()
    M = DB.Paths
end)

after_each(function()
    HTL.after_test()
end)

describe("ingest", function()
    it("+", function()
        M:insert({key = "abc", val = "xyz"})
        assert(#M:get() > 0)
        M:ingest()
        assert(#M:get() > 0)
        assert.is_nil(M:where({key = "abc"}))
    end)
end)
