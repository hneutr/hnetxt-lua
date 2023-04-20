local Path = require("hneutil.path")
local lyaml = require("lyaml")

local Config = require("hnetxt-lua.config")

describe("get", function()
    it("reads the right thing", function()
        assert.are.same({filename = ".project"}, Config.get("project"))
    end)
end)

