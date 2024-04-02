local Path = require("hl.Path")

local db = require("htl.db")
local log = require("htl.db.log")

before_each(function()
    db.before_test()
end)

after_each(function()
    db.after_test()
end)

describe("it", function()
    it("works", function()
        local Date = require("pl.Date")
        local d1 = Date({year = 2024, month = 2, day = 28})
        local d2 = Date({year = 2024, month = 3, day = 1})
        
        local delta = d2 - d1
        -- print(delta)
        d1 = Date({year = 2023, month = 2, day = 28})
        d2 = Date({year = 2023, month = 3, day = 1})
        
        delta = d2 - d1
        -- print(delta)
    end)
end)
