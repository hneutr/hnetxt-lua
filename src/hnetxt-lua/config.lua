table = require("hneutil.table")
string = require("hneutil.string")

local yaml = require("hneutil.yaml")
local Object = require("hneutil.object")
local Path = require("hneutil.path")

local Config = Object:extend()
Config.constants_dir = Path.joinpath(Path.home(), ".config/hnetxt/constants")
Config.data_dir = Path.joinpath(Path.home(), ".config/hnetxt/data")
Config.constants_suffix = ".yaml"

function Config.get(constants_type)
    local path = Path.joinpath(Config.constants_dir, constants_type)
    path = Path.with_suffix(path, Config.constants_suffix)
    return yaml.read(path)
end

return Config
