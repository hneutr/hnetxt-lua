local Header = require("hs.header")

describe("", function()
    it("", function()
        local h = Header({label = "hello", size = "small"})
        local s = tostring(h)
        -- print(require("inspect")(s))
        local h = Header({label = "steve", size = "large"})
        local s = tostring(h)
        -- print(require("inspect")(s))
        -- print(require("inspect")(Header({label = "hello"})))
    end)
end)

