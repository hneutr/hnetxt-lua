local Path = require("hl.Path")
local yaml = require("hl.yaml")

local Config = require("htl.config")

describe("get", function()
    it("reads the right thing", function()
        local config_name = "test_config"
        local content = {test = 1}
        local path = Path(Config.constants_dir):join(config_name .. ".yaml")
        yaml.write(tostring(path), content)
        assert.are.same(content, Config.get(config_name))
        path:unlink()
    end)
end)

