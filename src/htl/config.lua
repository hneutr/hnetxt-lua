local Yaml = require("hl.yaml")
local Object = require("hl.object")
local Path = require("hl.path")

local Config = Object:extend()
Config.constants_dir = Path.joinpath(Path.home(), ".config/hnetxt/constants")
Config.data_dir = Path.joinpath(Path.home(), ".config/hnetxt/data")
Config.constants_suffix = ".yaml"

function Config.get(constants_type)
    local path = Path.joinpath(Config.constants_dir, constants_type)
    path = Path.with_suffix(path, Config.constants_suffix)
    return Yaml.read(path)
end

function Config.get_data_dir(...)
    return Path.joinpath(Config.get('init').data_dir, ...)
end

return Config
