local utils = require("hl.utils")

describe("randint", function()
    it("no args", function()
        assert.are.same(1, utils.randint())
    end)

    it("set min", function()
        assert.are.same(2, utils.randint({min = 2}))
    end)

    it("set max", function()
        assert.not_nil(utils.randint({min = 1, max = 100}))
    end)

    it("seed", function()
        local args = {min = 1, max = 100, seed = 1234}
        assert.are.same(utils.randint(args), utils.randint(args))
    end)
end)
