local Path = require("hl.path")
local yaml = require("hl.yaml")

local Config = require("htl.config")

describe("get", function()
    it("reads the right thing", function()
        local config_name = "test_config"
        local content = {test = 1}
        local path = Path.joinpath(Config.constants_dir, config_name .. ".yaml")
        yaml.write(path, content)
        assert.are.same(content, Config.get(config_name))
        Path.unlink(path)
    end)
end)

