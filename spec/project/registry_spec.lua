local Path = require("hneutil.path")
local lyaml = require("lyaml")

local Registry = require("hnetxt-lua.project.registry")
local Config = require("hnetxt-lua.config")

local test_data_dir = Path.joinpath(Path.tempdir(), "test-project-data-dir")
local registry

before_each(function()
    Path.rmdir(test_data_dir, true)
    Registry.config = Config.get("project")
    Registry.config.data_dir = test_data_dir
    registry = Registry()
end)

describe("new", function()
    it("sets the path", function()
        local expected = Path.joinpath(test_data_dir, Config.get("project").registry_filename)
        assert.are.same(expected, registry.path)
    end)

end)

describe("get", function()
    it("returns empty table if not found", function()
        assert.falsy(Path.exists(registry.path))
        assert.are.same({}, registry:get())
    end)

    it("returns if found", function()
        local expected = {test = true}
        Path.write(registry.path, lyaml.dump({expected}))
        assert.are.same(expected, registry:get())
    end)
end)

describe("set", function()
    it("creates an empty table if no registry", function()
        registry:set()
        assert.are.same({}, registry:get())
    end)

    it("creates an empty table if no registry", function()
        local expected = {test = 1}

        registry:set(expected)
        assert.are.same(expected, registry:get())
    end)
end)

describe("set_entry", function()
    it("new", function()
        registry:set_entry("a", "b")
        assert.are.same({a = "b"}, registry:get())
    end)

    it("overwrites", function()
        registry:set_entry("a", "b")
        registry:set_entry("a", "c")
        assert.are.same({a = "c"}, registry:get())
    end)

    it("doesn't clobber", function()
        registry:set_entry("a", "b")
        registry:set_entry("x", "y")
        assert.are.same({a = "b", x = "y"}, registry:get())
    end)
end)

describe("get_entry", function()
    it("existing", function()
        registry:set_entry("a", "b")
        assert.are.same("b", registry:get_entry("a"))
    end)

    it("missing", function()
        assert.is_nil(registry:get_entry("a"))
    end)

    it("doesn't clobber", function()
        local r = Registry()
        registry:set_entry("a", "b")
        registry:set_entry("x", "y")
        assert.are.same({a = "b", x = "y"}, registry:get())
    end)
end)

describe("remove_entry", function()
    it("+", function()
        registry:set_entry("a", "b")
        registry:remove_entry("a")
        assert.is_nil(registry:get_entry("a"))
    end)
end)
