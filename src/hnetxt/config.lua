table = require("hneutil.table")
string = require("hneutil.string")
local Path = require("hneutil.path")
local lyaml = require("lyaml")

local constants_dir = Path.joinpath(Path.home(), ".config/hnetxt/constants")
local constants_suffix = ".yaml"

local M = {}

function M.get(constants_type)
    local path = Path.joinpath(constants_dir, constants_type)
    path = Path.with_suffix(path, constants_suffix)
    return lyaml.load(Path.read(path))
end

return M
