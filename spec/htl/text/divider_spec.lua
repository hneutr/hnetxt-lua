local htl = require("htl")
local Divider = require("htl.text.divider")

describe("str_is_a", function()
    local small = Divider("small")
    local medium = Divider("medium")
    local large = Divider("large")

    it("+", function()
        assert(small:str_is_a(tostring(small)))
    end)

    it("-", function()
        assert.falsy(small:str_is_a(tostring(large)))
    end)
end)
