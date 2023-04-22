local lyaml = require("lyaml")
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
        registry = lyaml.load(Path.read(self.path))
    end
    return registry
end

function Registry:set(registry)
    registry = registry or {}
    Path.write(self.path, lyaml.dump({registry}))
end

function Registry:set_entry(name, path)
    local registry = self:get()
    registry[name] = path
    self:set(registry)
end

function Registry:get_entry(name)
    return self:get()[name]
end

function Registry:remove_entry(name)
    self:set_entry(name, nil)
end


return Registry
