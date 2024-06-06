local htl = require("htl")
local M = require("htl.text.divider")

describe("str_is_a", function()
    local small = M({size = "small"})
    local medium = M({size = "medium"})
    local large = M({size = "large"})

    it("+", function()
        assert(small:str_is_a(tostring(small)))
    end)

    it("-", function()
        assert.falsy(small:str_is_a(tostring(large)))
    end)
end)

describe("tostring", function()
    it("works", function()
        M.dividers():foreach(function(d)
            assert.is_not.Nil(tostring(d))
        end)
    end)
end)
