local Path = require("hl.Path")
local yaml = require("hl.yaml")

local Config = require("htl.Config")

before_each(function()
    Config.before_test()
end)

after_each(function()
    Config.after_test()
end)

describe("get", function()
    it("reads the right thing", function()
        local p = Config.constants_dir:join("test-config.yaml")
        local content = {test = 1}
        yaml.write(p, content)
        assert.are.same(content, Config.get(p:stem()))
        p:unlink()
    end)
end)

describe("setup_path", function()
    local d1 = Config.test_root:join("d1")
    local d2 = d1:join("d2")

    before_each(function()
        Config.paths = Dict({root = Config.test_root})
    end)

    it("parent defined", function()
        assert.are.same(
            d1,
            Config.get_path("d1", {
                d1 = {
                    path = "d1",
                    parent = "root",
                },
            })
        )
    end)

    it("parent undefined", function()
        assert.are.same(
            d2,
            Config.get_path("d2", {
                d1 = {
                    path = "d1",
                    parent = "root",
                },
                d2 = {
                    path = "d2",
                    parent = "d1",
                }
            })
        )
    end)
end)
