local Path = require("hneutil.path")
local lyaml = require("lyaml")

local Config = require("hnetxt-lua.config")

describe("get", function()
    it("reads the right thing", function()
        local config_name = "test_config"
        local content = {test = 1}
        local path = Path.joinpath(Config.constants_dir, config_name .. ".yaml")
        Path.write(path, lyaml.dump({content}))

        assert.are.same(content, Config.get(config_name))
        Path.unlink(path)
    end)
end)

