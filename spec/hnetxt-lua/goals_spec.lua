local Path = require("hneutil.path")
local Goals = require("hnetxt-lua.goals")
local Config = require("hnetxt-lua.config")

describe("get_path", function()
    it("gets", function()
        local expected = Path.joinpath(Config.get("goals").dir, os.date("%Y%m") .. ".md")
        assert.are.same(expected, Goals())
    end)
end)
