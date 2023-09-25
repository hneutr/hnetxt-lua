local Yaml = require("hl.yaml")
local Path = require("hl.Path")
local Dict = require("hl.Dict")
local Object = require("hl.object")
local List = require("hl.List")

local Config = require("htl.config")

local Registry = Object:extend()
Registry.config = Config.get("project")
Registry.config.data_dir = Config.get_data_dir("projects")

function Registry:new(args)
    self = Dict.update(self, args or {})
    self.path = self.config.data_dir:join(self.config.registry_filename)
end

function Registry:get()
    local registry = {}
    if self.path:exists() then
        registry = Yaml.read(self.path)
    end
    return Dict(registry)
end

function Registry:set(registry)
    registry = Dict.from(registry or {})
    local _registry = Dict()
    for _, k in ipairs(List(registry:keys()):sorted()) do
        _registry[k] = registry[k]
    end

    Yaml.write(self.path, _registry)
end

function Registry:set_entry(name, path)
    local registry = self:get()
    if path ~= nil then
        path = tostring(path)
    end
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
