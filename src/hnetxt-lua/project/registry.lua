local yaml = require("hneutil.yaml")
local Object = require("hneutil.object")
local Path = require("hneutil.path")

table = require("hneutil.table")
string = require("hneutil.string")

local Config = require("hnetxt-lua.config")

local Registry = Object:extend()
Registry.config = Config.get("project")

function Registry:new(args)
    self = table.default(self, args or {})
    self.path = Path.joinpath(self.config.data_dir, self.config.registry_filename)
end

function Registry:get()
    local registry = {}
    if Path.exists(self.path) then
        registry = yaml.read(self.path)
    end
    return registry
end

function Registry:set(registry)
    registry = registry or {}
    yaml.write(self.path, registry)
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
