local Path = require("hl.path")
local yaml = require("hl.yaml")

local Registry = require("htl.project.registry")
local Config = require("htl.config")

local temp_registry_path = Path.tempdir:join("test-registry.yaml")
local registry_path = Registry.path

before_each(function()
    temp_registry_path:unlink()
    Registry.path = temp_registry_path
end)

after_each(function()
    Registry.path = registry_path
end)

describe("get", function()
    it("returns empty table if not found", function()
        assert.falsy(Registry.path:exists())
        assert.are.same({}, Registry.get())
    end)

    it("returns if found", function()
        local expected = {test = true}
        yaml.write(Registry.path, expected)
        assert.are.same(expected, Registry.get())
    end)
end)

describe("set", function()
    it("creates an empty table if no registry", function()
        Registry.set()
        assert.are.same({}, Registry.get())
    end)

    it("creates an empty table if no registry", function()
        local expected = {test = 1}

        Registry.set(expected)
        assert.are.same(expected, Registry.get())
    end)
end)

describe("set_entry", function()
    it("new", function()
        Registry.set_entry("a", "b")
        assert.are.same({a = "b"}, Registry.get())
    end)

    it("overwrites", function()
        Registry.set_entry("a", "b")
        Registry.set_entry("a", "c")
        assert.are.same({a = "c"}, Registry.get())
    end)

    it("doesn't clobber", function()
        Registry.set_entry("a", "b")
        Registry.set_entry("x", "y")
        assert.are.same({a = "b", x = "y"}, Registry.get())
    end)
end)

describe("get_entry_dir", function()
    it("existing", function()
        Registry.set_entry("a", "b")
        assert.are.same(Path("b"), Registry.get_entry_dir("a"))
    end)

    it("missing", function()
        assert.is_nil(Registry.get_entry_dir("a"))
    end)

    it("doesn't clobber", function()
        Registry.set_entry("a", "b")
        Registry.set_entry("x", "y")
        assert.are.same({a = "b", x = "y"}, Registry.get())
    end)
end)

describe("remove_entry", function()
    it("+", function()
        Registry.set_entry("a", "b")
        Registry.remove_entry("a")
        assert.is_nil(Registry.get_entry_dir("a"))
    end)
end)

describe("get_entry_name", function()
    it("+: exact match", function()
        Registry.set_entry("a", "/1/2/3")
        Registry.set_entry("b", "/4/5/6")
        assert.are.same("b", Registry.get_entry_name("/4/5/6"))
    end)

    it("+: subdir", function()
        Registry.set_entry("a", "/1/2/3")
        Registry.set_entry("b", "/4/5/6")
        assert.are.same("b", Registry.get_entry_name("/4/5/6/7"))
    end)
end)
