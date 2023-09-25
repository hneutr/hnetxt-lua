local Yaml = require("hl.yaml")
local Object = require("hl.object")
local Path = require("hl.Path")

local Config = Object:extend()
Config.constants_dir = Path.home:join(".config/hnetxt/constants")
Config.constants_suffix = ".yaml"

function Config.get(constants_type)
    local path = Config.constants_dir:join(constants_type):with_suffix(Config.constants_suffix)
    return Yaml.read(path)
end

function Config.get_data_dir(...)
    return Path(Config.get('init').data_dir):join(...)
end

return Config
