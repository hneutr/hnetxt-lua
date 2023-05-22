local Yaml = require("hl.yaml")
local Path = require("hl.path")
local Dict = require("hl.Dict")
local Object = require("hl.object")

local Config = require("htl.config")

local Registry = Object:extend()
Registry.config = Config.get("project")

function Registry:new(args)
    self = Dict.update(self, args or {})
    self.path = Path.joinpath(self.config.data_dir, self.config.registry_filename)
end

function Registry:get()
    local registry = {}
    if Path.exists(self.path) then
        registry = Yaml.read(self.path)
    end
    return registry
end

function Registry:set(registry)
    registry = registry or {}
    Yaml.write(self.path, registry)
end

function Registry:set_entry(name, path)
    local registry = self:get()
    registry[name] = path
    self:set(registry)
end

function Registry:get_entry_dir(name)
    return self:get()[name]
end

function Registry:remove_entry(name)
    self:set_entry(name, nil)
end

function Registry:get_entry_name(dir)
    for name, path in pairs(self:get()) do
        if dir == path or Path.is_relative_to(dir, path) then
            return name
        end
    end

    return nil
end

return Registry
