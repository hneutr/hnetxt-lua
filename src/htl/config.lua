local Yaml = require("hl.yaml")
local Dict = require("hl.Dict")
local Object = require("hl.object")
local Path = require("hl.Path")

local Config = Object:extend()
Config.constants_dir = Path.home:join(".config/hnetxt/constants")
Config.data_dir = Path.home:join(".data")
Config.constants_suffix = ".yaml"

function Config.get(constants_type)
    local path = Config.constants_dir:join(constants_type):with_suffix(Config.constants_suffix)
    return Yaml.read(path)
end

function Config.get_dir(constants_type)
    local d = Dict()
    Config.constants_dir:join(constants_type):glob("%.yaml$"):foreach(function(p)
        d[p:stem()] = Yaml.read(p)
    end)
    return d
end

return Config
